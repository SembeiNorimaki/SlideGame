extends Node
## Autoload "Store": one-time (non-consumable) in-app purchases, reusable
## across games. Register product ids, then use is_owned() / buy().
##
## Backends, picked automatically at startup:
## - GOOGLE_PLAY: the official GodotGooglePlayBilling plugin is installed and
##   running on Android. Google Play is the source of truth for ownership:
##   purchases are re-checked on every launch and every time the app comes back
##   to the foreground, and anything Google no longer reports (refunds) is revoked.
## - DEBUG: no plugin, debug build (editor / desktop). Purchases succeed
##   instantly so the unlock flow can be tested without the Play Store.
## - NONE: no plugin, release build. Nothing can be bought.
##
## Ownership is cached locally (signed per device) only so the game still
## works offline; the cache is overwritten by Google's answer when online.

signal owned_changed(product_id: String, owned: bool)
signal price_received(product_id: String, formatted_price: String)
signal purchase_pending(product_id: String)
## reason is "cancelled" when the player backed out of the payment sheet.
signal purchase_failed(product_id: String, reason: String)

enum Backend { NONE, GOOGLE_PLAY, DEBUG }

const PLUGIN_SINGLETON := "GodotGooglePlayBilling"
const CACHE_PATH := "user://store.cfg"
## Change per game. Makes the local cache non-trivial to forge by hand.
const CACHE_SALT := "slidegame-7c1e9f"

# Mirrors of BillingClient enums. The plugin's BillingClient class only exists
# when the plugin is installed, so it's never referenced by name here.
const _OK := 0
const _USER_CANCELED := 1
const _ITEM_ALREADY_OWNED := 7
const _PURCHASED := 1
const _PENDING := 2
const _INAPP := 0

var backend: Backend = Backend.NONE

var _client: Node  # BillingClient (from the plugin)
var _products := PackedStringArray()
var _owned := {}
var _prices := {}
var _details_ready := false
var _buying := ""
var _retry_delay := 2.0


func _ready() -> void:
	_load_cache()
	if Engine.has_singleton(PLUGIN_SINGLETON):
		_client = _new_billing_client()
	if _client:
		backend = Backend.GOOGLE_PLAY
		add_child(_client)
		_client.connected.connect(_on_connected)
		_client.disconnected.connect(_reconnect_later)
		_client.connect_error.connect(func(_code, msg): push_warning("Billing connect error: %s" % msg); _reconnect_later())
		_client.query_product_details_response.connect(_on_product_details)
		_client.query_purchases_response.connect(_on_purchases_queried)
		_client.on_purchase_updated.connect(_on_purchase_updated)
		_client.acknowledge_purchase_response.connect(_on_acknowledged)
		_client.start_connection()
	elif OS.is_debug_build():
		backend = Backend.DEBUG


## Declare which products this game sells (ids as set in the Play Console).
func register_products(ids: PackedStringArray) -> void:
	for id in ids:
		if not _products.has(id):
			_products.append(id)
	if backend == Backend.DEBUG:
		for id in ids:
			_prices[id] = "test"
			price_received.emit(id, "test")
	elif _is_connected():
		_query_all()


## Whether buying is possible at all on this platform/build.
func can_purchase() -> bool:
	return backend != Backend.NONE


func is_owned(product_id: String) -> bool:
	return _owned.has(product_id)


## Localized price (e.g. "CHF 2.00") once Google Play has sent it, else "".
func get_price(product_id: String) -> String:
	return _prices.get(product_id, "")


## Opens the payment sheet. The result arrives via owned_changed,
## purchase_pending or purchase_failed.
func buy(product_id: String) -> void:
	if is_owned(product_id):
		return
	match backend:
		Backend.NONE:
			purchase_failed.emit(product_id, "Purchases are not available here")
		Backend.DEBUG:
			await get_tree().create_timer(0.6).timeout
			_grant(product_id)
		Backend.GOOGLE_PLAY:
			if not _details_ready:
				purchase_failed.emit(product_id, "Store not ready, please try again")
				refresh()
				return
			_buying = product_id
			var r: Dictionary = _client.purchase(product_id)
			if r.get("response_code", -1) == _ITEM_ALREADY_OWNED:
				refresh()
			elif r.get("response_code", -1) != _OK:
				_buying = ""
				purchase_failed.emit(product_id, str(r.get("debug_message", "Purchase failed")))


## Re-asks Google Play what the player owns ("restore purchases").
func refresh() -> void:
	if _is_connected():
		_query_all()
	elif backend == Backend.GOOGLE_PLAY:
		_client.start_connection()


## Debug builds only: forget debug purchases to test the locked state again.
func debug_reset() -> void:
	if backend == Backend.DEBUG:
		for id in _owned.keys():
			_revoke(id)


func _notification(what: int) -> void:
	# Pending payments (e.g. cash at a shop) can complete while we're in the background.
	if what == NOTIFICATION_APPLICATION_RESUMED:
		refresh()


# ---- Google Play ---------------------------------------------------------

func _new_billing_client() -> Node:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == &"BillingClient":
			return load(c["path"]).new()
	push_error("GodotGooglePlayBilling singleton found but BillingClient class is missing; is the plugin enabled?")
	return null


func _is_connected() -> bool:
	return backend == Backend.GOOGLE_PLAY and _client.is_ready()


func _query_all() -> void:
	if not _products.is_empty():
		_client.query_product_details(_products, _INAPP)
	_client.query_purchases(_INAPP)


func _on_connected() -> void:
	_retry_delay = 2.0
	_query_all()


func _reconnect_later() -> void:
	await get_tree().create_timer(_retry_delay).timeout
	_retry_delay = minf(_retry_delay * 2.0, 60.0)
	if not _client.is_ready():
		_client.start_connection()


func _on_product_details(r: Dictionary) -> void:
	if r.response_code != _OK:
		push_warning("Product details query failed: %s" % r.get("debug_message", ""))
		return
	_details_ready = true
	for d in r.product_details:
		var offers = d.get("one_time_purchase_offer_details_list")
		var price: String = offers[0].get("formatted_price", "") if offers else ""
		_prices[d.product_id] = price
		price_received.emit(d.product_id, price)


func _on_purchases_queried(r: Dictionary) -> void:
	if r.response_code != _OK:
		return  # offline etc.: keep the cached state
	var seen := {}
	for p in r.purchases:
		_handle_purchase(p, seen)
	# Owned before, but Google no longer reports it: refunded or revoked.
	for id in _owned.keys():
		if _products.has(id) and not seen.has(id):
			_revoke(id)


func _on_purchase_updated(r: Dictionary) -> void:
	var id := _buying
	_buying = ""
	match int(r.response_code):
		_OK:
			for p in r.purchases:
				_handle_purchase(p)
		_USER_CANCELED:
			purchase_failed.emit(id, "cancelled")
		_ITEM_ALREADY_OWNED:
			refresh()
		_:
			purchase_failed.emit(id, str(r.get("debug_message", "Purchase failed")))


func _handle_purchase(p: Dictionary, seen = null) -> void:
	for id in p.product_ids:
		match int(p.purchase_state):
			_PURCHASED:
				if seen != null:
					seen[id] = true
				_grant(id)
			_PENDING:
				purchase_pending.emit(id)
	# Must be acknowledged within 3 days or Google refunds it automatically.
	if int(p.purchase_state) == _PURCHASED and not p.is_acknowledged:
		_client.acknowledge_purchase(p.purchase_token)


func _on_acknowledged(r: Dictionary) -> void:
	if r.response_code != _OK:
		# Still unacknowledged, so the next refresh() will try again.
		push_warning("Acknowledge failed: %s" % r.get("debug_message", ""))


# ---- ownership + cache -----------------------------------------------------

func _grant(id: String) -> void:
	if _owned.has(id):
		return
	_owned[id] = true
	_save_cache()
	owned_changed.emit(id, true)


func _revoke(id: String) -> void:
	if not _owned.erase(id):
		return
	_save_cache()
	owned_changed.emit(id, false)


func _signature(id: String) -> String:
	var device := "" if OS.has_feature("web") else OS.get_unique_id()
	return ("%s:%s:%s" % [CACHE_SALT, id, device]).sha256_text()


func _load_cache() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CACHE_PATH) != OK or not cfg.has_section("owned"):
		return
	for id in cfg.get_section_keys("owned"):
		var sig = cfg.get_value("owned", id)
		if sig is String and sig == _signature(id):
			_owned[id] = true


func _save_cache() -> void:
	var cfg := ConfigFile.new()
	for id in _owned:
		cfg.set_value("owned", id, _signature(id))
	cfg.save(CACHE_PATH)

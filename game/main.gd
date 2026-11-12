extends Node
## Game-specific glue: switches between screens and reacts to the store.
## Data lives in GameData; the shared screens only emit signals.

const MAIN_MENU := preload("res://shared/ui/screens/main_menu/main_menu.tscn")
const SET_SELECT := preload("res://shared/ui/screens/set_select/set_select.tscn")
const SETTINGS := preload("res://shared/ui/screens/settings/settings_screen.tscn")
const LEVEL_SELECT := preload("res://shared/ui/screens/level_select/level_select.tscn")
const LEVEL := preload("res://game/levels/level_play.tscn")

var _current: Node
var _toast := Toast.new()


func _ready() -> void:
	add_child(_toast)
	Store.owned_changed.connect(_on_owned_changed)
	Store.price_received.connect(func(_id, _price): _refresh_store_screens())
	Store.purchase_pending.connect(func(_id): _toast.show_message("Payment pending. The full game unlocks when it completes."))
	Store.purchase_failed.connect(_on_purchase_failed)
	show_main_menu()


func show_main_menu() -> void:
	var menu: MainMenu = MAIN_MENU.instantiate()
	menu.game_title = "Slide Game"
	menu.footer_text = "v0.3.0"
	menu.continue_available = GameData.has_progress()
	menu.show_buy_button = Store.can_purchase() and not GameData.owns_full_game()
	menu.buy_button_text = _buy_text()
	menu.new_game_requested.connect(_on_new_game)
	menu.continue_requested.connect(show_set_select)
	menu.buy_requested.connect(buy_full_game)
	menu.settings_requested.connect(show_settings)
	_switch_to(menu)


func show_settings() -> void:
	var screen: SettingsScreen = SETTINGS.instantiate()
	_switch_to(screen)
	screen.setup(GameData.languages, GameData.DIFFICULTIES)
	screen.back_requested.connect(show_main_menu)
	screen.reset_progress_confirmed.connect(func():
		GameData.reset_progress()
		_toast.show_message("Progress reset"))


func show_set_select() -> void:
	var select: SetSelect = SET_SELECT.instantiate()
	_switch_to(select)
	var entries := []
	for s in GameData.sets:
		var locked := not GameData.is_unlocked(s)
		entries.append({
			"id": s.id,
			"title": tr(s.title),
			"subtitle": tr("Unlock with the full game") if locked else tr("%d / %d completed") % [s.progress.completed_count(), s.level_count()],
			"locked": locked,
		})
	select.set_entries(entries)
	select.set_selected.connect(show_level_select)
	select.locked_set_selected.connect(func(_id): buy_full_game())
	select.back_requested.connect(show_main_menu)


func show_level_select(set_id: String) -> void:
	var game_set := GameData.get_set(set_id)
	var select: LevelSelect = LEVEL_SELECT.instantiate()
	select.columns = 4
	select.title = tr(game_set.title)
	_switch_to(select)
	select.use_progress(game_set.progress)
	select.level_selected.connect(func(level: int): start_level(set_id, level))
	select.back_requested.connect(show_set_select)


func start_level(set_id: String, level: int) -> void:
	var scene := LEVEL.instantiate()
	scene.game_set_id = set_id
	scene.level = level
	scene.completed.connect(_on_level_completed.bind(set_id, level))
	scene.exited.connect(show_level_select.bind(set_id))
	_switch_to(scene)


func buy_full_game() -> void:
	if GameData.owns_full_game():
		return
	Store.buy(GameData.full_game_product_id)


func _buy_text() -> String:
	var price := Store.get_price(GameData.full_game_product_id)
	return tr("Buy full game (%s)") % price if price != "" else tr("Buy full game")


func _on_new_game() -> void:
	if GameData.has_progress():
		var ok := await ConfirmDialog.ask(self, "Start a new game?",
				"This deletes your progress in every set.", "Start")
		if not ok:
			return
	GameData.reset_progress()
	show_set_select()


func _on_level_completed(set_id: String, level: int) -> void:
	var game_set := GameData.get_set(set_id)
	game_set.progress.complete_level(level)
	if level < game_set.level_count():
		start_level(set_id, level + 1)  # go straight on to the next level
	else:
		show_level_select(set_id)  # set finished  # TODO: a "set complete" screen


func _on_owned_changed(product_id: String, owned: bool) -> void:
	if product_id == GameData.full_game_product_id and owned:
		_toast.show_message("Full game unlocked. Enjoy!")
	_refresh_store_screens()


func _on_purchase_failed(_id: String, reason: String) -> void:
	if reason != "cancelled":
		_toast.show_message(reason)


## Rebuilds the screens whose content depends on what the player owns.
func _refresh_store_screens() -> void:
	if _current is MainMenu:
		show_main_menu()
	elif _current is SetSelect:
		show_set_select()


func _switch_to(screen: Node) -> void:
	if _current:
		_current.queue_free()
	_current = screen
	add_child(screen)
	move_child(_toast, -1)

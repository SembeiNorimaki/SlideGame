# Selling the full game on Google Play

The game sells one **one-time, non-consumable in-app product** with id
`full_game` (set in `game/data/sets.json`). Owning it unlocks every set with
`"free": false`. The code lives in `shared/store/store.gd` (autoload `Store`).

## How ownership is decided

- Google Play is the source of truth. On every launch, and every time the app
  returns to the foreground, `Store` asks Google Play which products the
  player owns (`query_purchases`). Anything Google no longer reports
  (refund, chargeback) is revoked.
- New purchases are **acknowledged** right away. Google refunds purchases that
  aren't acknowledged within 3 days.
- **Pending** payments (e.g. cash at a shop) don't unlock anything until they
  complete. The game re-checks when the app comes back to the foreground.
- Reinstalling or using a new phone: the launch check restores the purchase
  automatically; there's no "restore purchases" button to press.
- The local cache (`user://store.cfg`) only exists so the game also works
  offline. It is signed per device, so copying it or typing a flag into it
  doesn't unlock anything.

What this does **not** stop: someone who patches the APK itself. That needs
server-side verification with the Google Play Developer API (a backend you
host). For a small paid unlock most games accept the client-side check.

## One-time setup

1. **Install the plugin** (official, by the Godot team):
   AssetLib tab in the editor → search "Godot Google Play Billing" → Download →
   Install (keep "Ignore asset root" unchecked). It lands in
   `addons/GodotGooglePlayBilling/`. Then Project → Project Settings →
   Plugins → enable **GodotGooglePlayBilling**.
2. **Android export preset**: enable `gradle/use_gradle_build`
   (install the Android build template when asked), and add `*.json` to
   *Filters to export non-resource files*.
3. **Play Console**:
   - Create the app; its package name must match the export preset.
   - Upload a build that includes the plugin to the **Internal testing** track
     (billing only activates for a package after one upload).
   - Monetize → Products → In-app products → create `full_game`, set the
     price, **activate** it.
   - Setup → License testing → add your Google account so test purchases
     aren't charged.
4. Install the build from the internal testing link on your phone and buy.

## Testing without the Play Store

In the editor and desktop debug builds there's no plugin, so `Store` uses a
fake store: "Buy full game (test)" unlocks instantly. Call
`Store.debug_reset()` (or delete `user://store.cfg`) to lock it again.
Release builds without the plugin hide the buy button.

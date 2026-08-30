# 🧩 ShaguTweaks Extras — ClassicAPI

A complementary fork of [ShaguTweaks-extras](https://github.com/paokkerkir/ShaguTweaks-extras) for **ShaguTweaks-ClassicAPI** and **Turtle WoW-like servers**.

Focused on **stability, compatibility and performance** while keeping the original ShaguTweaks Extras experience.

> This fork requires **ClassicAPI** and is designed to be used with [ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI).

## 🔌 Requirements

- **[ClassicAPI](https://github.com/brues-code/ClassicAPI) — required**
- **[ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI) — required**
- **[SuperWoW](https://github.com/balakethelock/SuperWoW) — optional / recommended**

ClassicAPI is the main API layer. ShaguTweaks-ClassicAPI provides the shared `ShaguTweaks.API` bridge used by Extras. SuperWoW is optional and may be used by ShaguTweaks-ClassicAPI for additional cast/GUID information.

## 📦 Installation

1. Install **ClassicAPI**.
2. Install **ShaguTweaks-ClassicAPI** and rename its folder to `ShaguTweaks`.
3. Optionally install **SuperWoW**.
4. Rename this addon folder to `ShaguTweaks-extras`.
5. Copy it to `World of Warcraft\Interface\AddOns\ShaguTweaks-extras`.
6. Restart the game.

Settings: **Esc → Advanced Options**.

> The `ShaguTweaks-extras` folder name must be kept for compatibility with bundled texture paths.

## ✨ Main changes

- ClassicAPI-backed integration through the shared `ShaguTweaks.API` layer.
- Removed modules already integrated into ShaguTweaks-ClassicAPI.
- Improved macro support with modern ClassicAPI-backed commands.
- Better macro icon and `#showtooltip` handling.
- Safer hooks and fewer destructive global overrides.
- Reduced unnecessary per-frame work and repeated UI scans.
- Improved raid-frame initialization and shared periodic updates.
- Reagent Counter now uses ClassicAPI spell reagent and item count data instead of tooltip scanning.
- Reveal World Map now uses live ClassicAPI map overlay data instead of bundled static map tables.
- Better Turtle WoW-like server compatibility for items, auras and UI behavior.
- Added Auction Alt-Buy and Buy Em All as optional merchant and auction conveniences.
- Buy Em All uses ClassicAPI merchant, item count and bag-family data, including specialty bags.
- Added modifier-aware Key-Down Casting with Shift/Ctrl/Alt binding support and an independent Alt Self-Cast option.
- Added Metric Range for metre labels in range tooltips without changing numeric values.
- Added optimized modules adapted from TokensWorth/ShaguTweaks-mods: Mouseover Right bars, Hide Macro Text, Unit Frame Abbreviated Names, Movable Unit Frames Extended, Cursor Tooltip and Hide Combat Tooltip.
- Movable Unit Frames Extended and Hide Combat Tooltip use ClassicAPI modifier-state events instead of permanent per-frame modifier polling.
- Various stability fixes across legacy ShaguTweaks Extras modules.

## 🔷 Mods using ClassicAPI integration

- Auction Alt-Buy
- Bag Item Click
- Bag Search Bar
- Buy Em All
- Key-Down Casting
- Alt Self-Cast
- Macro Icons
- Macro Tweaks
- Movable Unit Frames Extended
- Raid Frames
- Reagent Counter
- Reveal World Map
- Show Dispel Indicators
- Show Bags
- Show Micro Menu
- Hide Combat Tooltip
- Unit Frame Abbreviated Names

Other modules can also benefit indirectly from ClassicAPI through shared ShaguTweaks libraries and helpers.

## ⚙️ Modules

### Action Bar

- Center Vertical Actionbar
- Dragonflight Gryphons
- Floating Actionbar
- Reagent Counter
- Show Bags
- Show Micro Menu
- Key-Down Casting
- Alt Self-Cast
- Mouseover Right
- Mouseover Right 2
- Hide Macro Text

### Bags & Inventory

- Bag Item Click
- Bag Search Bar

### Merchant & Auction

- Auction Alt-Buy
- Buy Em All

### Tooltip & Items

- Metric Range
- Cursor Tooltip
- Hide Combat Tooltip

### Unit Frames

- Unit Frame Abbreviated Names
- Movable Unit Frames Extended

### World Map

- Reveal World Map

### Chat

- Chat Timestamps
- Center Text Input Box
- Enable Text Shadow

### Macro

- Macro Icons
- Macro Tweaks

Macro Tweaks adds convenient ClassicAPI-backed aliases:

- `/startattack`
- `/stopattack`
- `/focus`
- `/clearfocus`

### Raid Frames

- Enable Raid Frames
- Hide Party Frames
- Show Aggro Indicators
- Show Combat Feedback
- Show Dispel Indicators
- Show Group Headers
- Show Healing Predictions
- Use As Party Frames
- Use Compact Layout

## 🧹 Removed duplicates

The following modules are not included because improved versions already exist in ShaguTweaks-ClassicAPI:

- **Chat History** → integrated into **Chat Tweaks**
- **Show Energy Ticks** → integrated as **Energy & Mana Tick**
- **Improved Roll Frames** → already integrated and optimized in **ShaguTweaks-ClassicAPI**

## 🔧 Compatibility

- ShaguTweaks-ClassicAPI integration
- ClassicAPI integration
- Turtle WoW-like server integration
- SuperWoW integration

## 🙏 Credits

Original addon and modules by **Shagu**.

Additional maintenance and Turtle WoW work by **paokkerkir**.

ClassicAPI compatibility fork maintained by **Dusk-92**.

Additional requested modules adapted from **TokensWorth/ShaguTweaks-mods**, originally released under MIT by **GryllsAddons**. See `THIRD_PARTY_NOTICES.md`.

Released under the original **MIT License**.

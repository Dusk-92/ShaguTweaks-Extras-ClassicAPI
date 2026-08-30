# 🧩 ShaguTweaks Extras — ClassicAPI

A complementary fork of [ShaguTweaks-extras](https://github.com/paokkerkir/ShaguTweaks-extras) for **ShaguTweaks-ClassicAPI** and **Turtle WoW-like servers**.

Focused on **stability, compatibility and performance** while keeping the original ShaguTweaks Extras experience.

> This fork is designed to be used with [ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI).

## 🔌 Requirements

- **[ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI) — required**
- **[ClassicAPI](https://github.com/brues-code/ClassicAPI) — required through ShaguTweaks-ClassicAPI**
- **[SuperWoW](https://github.com/balakethelock/SuperWoW) — optional / recommended**

ClassicAPI is used through the shared `ShaguTweaks.API` compatibility layer where it provides a real benefit. Native Vanilla APIs are kept where ClassicAPI is not needed.

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

- ClassicAPI compatibility through the shared `ShaguTweaks.API` layer.
- Removed modules already integrated into ShaguTweaks-ClassicAPI.
- Improved macro support with modern ClassicAPI-backed commands.
- Better macro icon and `#showtooltip` handling.
- Safer hooks and fewer destructive global overrides.
- Reduced unnecessary per-frame work and repeated UI scans.
- Improved raid-frame initialization and shared periodic updates.
- Better Turtle WoW-like server compatibility for items, auras and UI behavior.
- Various stability fixes across legacy ShaguTweaks Extras modules.

## 🔷 Mods using ClassicAPI directly

- Bag Item Click
- Bag Search Bar
- Macro Icons
- Macro Tweaks
- Raid Frames
- Show Dispel Indicators
- Show Bags
- Show Micro Menu

Other modules remain on native Vanilla APIs where ClassicAPI does not provide a meaningful advantage.

## ⚙️ Modules

### Action Bar

- Center Vertical Actionbar
- Dragonflight Gryphons
- Floating Actionbar
- Reagent Counter
- Show Bags
- Show Micro Menu

### Chat

- Chat Timestamps
- Center Text Input Box
- Enable Text Shadow

### Bags & World Map

- Bag Item Click
- Bag Search Bar
- Reveal World Map

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

The following original Extras modules are not included because improved versions already exist in ShaguTweaks-ClassicAPI:

- **Chat History** → integrated into **Chat Tweaks**
- **Show Energy Ticks** → integrated as **Energy & Mana Tick**

## 🔧 Compatibility

- ShaguTweaks-ClassicAPI integration
- ClassicAPI integration
- Turtle WoW-like server compatibility
- SuperWoW compatibility

## 🙏 Credits

Original addon and modules by **Shagu**.

Additional maintenance and Turtle WoW work by **paokkerkir**.

ClassicAPI compatibility fork maintained by **Dusk-92**.

Released under the original **MIT License**.

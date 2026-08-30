# 🧩 ShaguTweaks Extras — ClassicAPI

A complementary fork of **ShaguTweaks-extras** intended to be used with
[Dusk-92/ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI).

The goal is to keep the useful Extras modules while removing functionality that
is already integrated into the main ShaguTweaks-ClassicAPI fork, hardening
legacy hooks, and using the shared `ShaguTweaks.API` ClassicAPI bridge where it
actually improves reliability.

## Requirements

- **ShaguTweaks-ClassicAPI** — required
- **ClassicAPI** — required indirectly by ShaguTweaks-ClassicAPI
- **SuperWoW** — optional, as in the main fork

## Installation

1. Install **ShaguTweaks-ClassicAPI** and rename its folder to `ShaguTweaks`.
2. Download this repository.
3. Rename this addon folder to **`ShaguTweaks-extras`**.
4. Copy it to `World of Warcraft\Interface\AddOns\ShaguTweaks-extras`.
5. Restart the game.

The `ShaguTweaks-extras` folder name is kept for compatibility with bundled
texture paths and the original addon layout.

## Removed duplicates

These modules are intentionally not shipped here because equivalent/improved
versions already exist in ShaguTweaks-ClassicAPI:

- **Chat History** → integrated into **Chat Tweaks**
- **Show Energy Ticks** → integrated as **Unit Frame Energy & Mana Tick**

## Included modules

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

### General
- Bag Item Click
- Bag Search Bar
- Reveal World Map

### Macro
- Macro Icons
- Macro Tweaks

### Raid
- Enable Raid Frames
- Hide Party Frames
- Show Aggro Indicators
- Show Combat Feedback
- Show Dispel Indicators
- Show Group Headers
- Show Healing Predictions
- Use As Party Frames
- Use Compact Layout

## Compatibility approach

ClassicAPI is consumed through the shared `ShaguTweaks.API` capability layer.
Modules that do not benefit from ClassicAPI are deliberately left on native
Vanilla UI APIs instead of adding unnecessary abstraction.

Legacy global replacements are reduced wherever the feature can be implemented
with the safer ShaguTweaks hook helpers.

## Credits

Original addon and modules by **Shagu**.

Additional maintenance and Turtle WoW 1.18.1 work by **paokkerkir**.

ClassicAPI fork maintenance and compatibility work by **Dusk-92**.

Released under the original MIT license.

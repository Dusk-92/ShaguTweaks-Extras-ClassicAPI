# Full audit — ShaguTweaks Extras ClassicAPI

Audit target: Turtle WoW / Vanilla 1.12 environment using
[Dusk-92/ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI)
and its shared `ShaguTweaks.API` ClassicAPI capability layer.

This document records the static audit performed on the fork. Runtime behavior
still requires in-game validation because the WoW 1.12 UI runtime cannot be
executed in GitHub.

## Scope

The upstream fork contained **25 Lua modules**. Two are duplicates of features
already integrated and improved in ShaguTweaks-ClassicAPI, leaving **23 modules**
in this Extras fork.

Audit areas:

- duplicate functionality with ShaguTweaks-ClassicAPI
- ClassicAPI opportunities and safe Vanilla fallbacks
- destructive global function replacement
- permanent or excessive `OnUpdate` work
- tooltip/container scans
- macro action-slot correctness
- raid-frame update architecture
- nil/global-state hazards
- Turtle WoW 1.18.1 world-map compatibility
- addon load order and dependency assumptions
- TOC, README, assets and locale stubs

## Removed duplicates

### Chat History — removed

Equivalent functionality is already integrated into
`ShaguTweaks-ClassicAPI/mods/chat-tweaks.lua`, including history persistence,
restore and additional chat compatibility fixes. Keeping the Extras copy would
stack two `ChatFrame.AddMessage` wrappers and duplicate saved-history work.

### Show Energy Ticks — removed

Equivalent functionality is already integrated as
`unitframes-energy-tick.lua` in ShaguTweaks-ClassicAPI. The main fork version
also contains timing and sizing improvements, so the older Extras copy is
strictly redundant.

## Module-by-module audit

### Action Bar

#### Dragonflight Gryphons — retained

No ClassicAPI benefit. Event-driven and inexpensive. Bundled texture paths
require the addon folder to remain named `ShaguTweaks-extras`.

#### Floating Actionbar — fixed

Previously replaced `ReputationWatchBar_Update` globally. It now uses the
shared ShaguTweaks safe hook helper and preserves Blizzard/Turtle behavior.
Added a guard for the XP-bar background region.

#### Reagent Counter — optimized

The tooltip scan is unavoidable because Vanilla exposes no direct action-button
reagent API. Previously an `OnUpdate` ran permanently and all 120 action slots
were rescanned after every bag event.

Now the frame sleeps while idle. Action-layout events request a one-frame
tooltip rescan; `BAG_UPDATE` only refreshes counts for reagents already known.
Button and count-font accesses are also nil-guarded.

#### Center Vertical Actionbar — retained

Simple one-time frame positioning. No ClassicAPI benefit and no hot-path work.

#### Show Bags — fixed / optimized

Uses ClassicAPI-aware modifier helpers. Modifier polling is throttled to 50 ms.
Initialization is guarded against repeated `PLAYER_ENTERING_WORLD` work.
Child anchors are cleared before reparenting.

The old `frame.Show = frame:Show()` trick was replaced by the explicit
`frame.Show = nil` restoration followed by the native `:Show()` method.

#### Show Micro Menu — fixed / optimized

Same hardening as Show Bags. The configured `panelmicro.scale` value was
previously defined but never applied; it is now used.

### Bags / General

#### Bag Item Click — hardened

ClassicAPI-aware Shift state is used where available.

The old replacement of `GameTooltip.SetBagItem` was removed and replaced by a
safe post-hook.

The `UseContainerItem` interception remains intentionally global because this
feature must be able to suppress the default item use while trade/auction
actions are active. The original function is preserved and called for the
normal path.

#### Bag Search Bar — fixed / ClassicAPI-aware

Fixed a possible nil dereference where the icon texture was read before the bag
button had been validated.

Item IDs/names now prefer `ShaguTweaks.API.GetContainerItemID` and
`GetItemNameByID`, with the original hyperlink parser retained as fallback.
This improves compatibility with ClassicAPI item caches and custom Turtle items.

#### Reveal World Map — critical fix / hardened

Fixed a broken `create_hash` call that omitted the `prefix` argument and
shifted all remaining parameters. This could feed a number into string
operations during map overlay processing.

The module no longer manually replaces `WorldMapFrame_Update`. A pre-hook
clears overlay textures and a post-hook adds the reveal layer while preserving
the native/Turtle updater.

Internal overlay state is now anchored explicitly on `WorldMapFrame` instead
of relying on the implicit global `this` value.

Turtle WoW 1.18.1 custom map overlay data from upstream is preserved.

### Chat

#### Center Text Input Box — fixed

Previously replaced `UIParent_ManageFramePositions` globally. It now uses the
safe ShaguTweaks hook helper and reapplies its position after the native layout
manager runs.

#### Enable Text Shadow — retained

One-time font flag update. No ClassicAPI benefit.

#### Chat Timestamps — hardened

A per-frame guard prevents duplicate `AddMessage` wrapping.

This wrapper is intentionally retained because timestamps must alter the
message before it reaches the underlying Chat Tweaks history/output pipeline.

### Macro

#### Macro Icons — fixed / optimized / ClassicAPI-aware

Uses `ShaguTweaks.API.GetActionInfo` when available to resolve macro action
IDs.

Fixed an action-slot bug: the old code fetched the fallback texture using the
local button index instead of the real paged action slot. This was wrong on
paged/bonus bars.

Macro bodies are now cached once per actionbar event instead of scanning all 36
macro slots again for every button.

`#showtooltip` retains priority, followed by the original supported
`--showtooltip`, `/cast`, `/pfcast` and `CastSpellByName` patterns.

#### Macro Tweaks — fixed / ClassicAPI-aware

Registers a deliberately small set of modern-style slash commands backed by
ClassicAPI:

- `/startattack [unit]` → `StartAttack(unit)`
- `/stopattack` → `StopAttack()`
- `/focus [unit]` → `FocusUnit(unit)` (defaults to current target)
- `/clearfocus` → `ClearFocus()`

Each alias is only registered when no existing global `SLASH_*` alias already
claims the same command. ShaguTweaks-specific command IDs are used internally,
avoiding collisions with generic `SlashCmdList.STARTATTACK` / `FOCUS` keys.
This also fixes a Vanilla failure mode where a handler key could exist without
the actual slash alias, leaving macros to print the stock `/help` hint.

No `/castnotoggle` alias is added: ClassicAPI already recognizes
`CastSpellNoToggle("Spell")` directly inside macro bodies and tags the action
slot correctly, so an extra slash command would be redundant.

Container item lookup now prefers ClassicAPI item IDs/names.

Numeric `/use` and `/equip` parsing is anchored so arbitrary item names that
contain digits are not accidentally interpreted as inventory slots.

The `SendChatMessage` interception and edit-box history wrapper remain
intentional because these features must suppress macro metadata/history rather
than merely observe calls.

### Raid

#### Enable Raid Frames — major performance refactor

The upstream design ran every component update callback from every visible
raidframe on every rendered frame.

The new design separates three update classes:

1. normal WoW events
2. one shared 250 ms ticker for all raidframes
3. per-frame callbacks only for components that explicitly require animation

This removes the old per-unit 250 ms timers and reduces the raid tick to one
shared `OnUpdate`.

Additional fixes:

- range helper now uses its `unitstr` argument instead of implicit `this`
- positional range works whenever `UnitPosition` exists, with Vanilla
  `CheckInteractDistance` fallback
- undefined health-bar alpha replaced with explicit `1`
- unknown mana power types have a safe fallback color
- compact layout is handled directly by the base text component
- raid-toggle drag `OnUpdate` exists only while actually dragging
- ClassicAPI-aware Shift detection is used for dragging

#### Use As Party Frames — hardened

The wrapped raid event handler is now nil-guarded before invocation.

#### Show Group Headers — retained

Event-driven and low cost. No ClassicAPI-specific data required.

#### Show Combat Feedback — optimized

Explicitly marked as the only default raid component requiring frame-by-frame
animation. Removed unnecessary globally named FontString creation and fixed the
frame reference used by the UNIT_COMBAT filter.

#### Show Dispel Indicators — ClassicAPI-aware

Uses ClassicAPI's positional `UnitDebuff` path when available and falls back to
the Vanilla 1.12 three-value layout otherwise.

#### Show Aggro Indicators — fixed

The unit-string table was accidentally global; it is now local. Repeated
`GetTime()` calls inside one cache check were collapsed to one value.

The heuristic itself is retained because Vanilla has no authoritative threat
API for this use case.

#### Show Healing Predictions — optimized

Prediction refresh moved from every rendered frame to the shared 250 ms ticker.
Widths use the actual health-bar width instead of a hardcoded 62 pixels.
Prediction textures hide cleanly when no heal is incoming.

#### Use Compact Layout — fixed

Compact state is now explicit on the raidframe. The header-adjustment waiter is
throttled and no longer disables itself before headers actually exist.

#### Hide Party Frames — rewritten

Removed the permanent polling `OnUpdate`, removed the accidental nested loop
using the same index variable, and replaced it with raid Show/Hide hooks plus
roster/party events.

Original PartyFrame `Show` methods are preserved and restored when raidframes
are inactive.

## Intentional interceptions that remain

A complete audit should distinguish unsafe accidental overrides from wrappers
required by the feature. The following remain intentionally:

- `UseContainerItem` — Bag Item Click must suppress default use in
  trade/auction contexts.
- `SendChatMessage` — Macro Tweaks must suppress `#showtooltip` metadata.
- `ChatFrameEditBox.AddHistoryLine` — Macro Tweaks must suppress executed
  macro commands from input history.
- `ChatFrame.AddMessage` — Chat Timestamps must modify text before downstream
  processing.
- PartyMemberFrame `Show` methods — temporarily suppressed only while the
  custom raidframe is active and restored afterwards.

## Core / packaging audit

### TOC

- dependency remains `ShaguTweaks`; ClassicAPI is already required by the main
  ShaguTweaks-ClassicAPI fork
- duplicate modules removed
- title/author/notes updated for the ClassicAPI fork

### main.lua

Provider label updated to `Extras ClassicAPI`.

### Assets

All four TGA assets are still referenced by retained modules. The
`ShaguTweaks-extras` installation folder name must therefore be preserved.

### Locales

The eight translation files are currently empty stubs inherited from upstream.
They are harmless and kept for the standard ShaguTweaks locale structure; all
module strings currently fall back to the main translation system.

### License / credits

MIT license retained. Original Shagu authorship and paokkerkir maintenance are
credited in the README.

## In-game validation matrix

Static audit is complete. Before merging to the stable branch, test:

- clean login and `/reload` with ClassicAPI + ShaguTweaks + Extras only
- login with the usual addon set enabled
- all actionbar pages, stance/bonus bars and reagent-count changes
- bag search with bags, keyring and bank
- Bag Item Click in trade, AH browse and AH sell; verify Shift bypass
- macros using `#showtooltip`, `/cast`, `/pfcast`, `CastSpellByName`,
  action-page changes and bonus bars
- world-map reveal toggle across Vanilla and Turtle custom zones
- 5-player party mode and normal PartyFrames restoration
- raids at several sizes, including Compact layout
- dispel indicators for applicable classes
- healing prediction / resurrection state
- aggro indicators and combat feedback
- drag raid toggle and reduced-actionbar panels
- repeated zone/instance transitions, relog and character changes
- Lua error collection and FPS comparison in a populated raid

## Merge policy

Do not merge this audit branch solely on static analysis. Treat the branch as a
test candidate until the in-game matrix has passed without Lua errors or UI
regressions.

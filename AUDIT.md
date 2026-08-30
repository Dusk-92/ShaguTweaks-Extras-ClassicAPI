# Full audit — ShaguTweaks Extras ClassicAPI

Audit target: Turtle WoW / Vanilla 1.12 environment using
[Dusk-92/ShaguTweaks-ClassicAPI](https://github.com/Dusk-92/ShaguTweaks-ClassicAPI)
and its shared `ShaguTweaks.API` ClassicAPI capability layer.

This document records the static audit performed on the fork. Runtime behavior
still requires in-game validation because the WoW 1.12 UI runtime cannot be
executed in GitHub.

## ClassicAPI-first conversion audit — 2026-08-30

The retained Extras modules were audited again against the current ClassicAPI
API surface. The goal of this pass is the same architecture as
ShaguTweaks-ClassicAPI itself:

```
Extras module
    ↓
ShaguTweaks.API
    ↓
ClassicAPI first
    ↓
central Vanilla fallback only when required
```

The conversion is paired with the ShaguTweaks-ClassicAPI branch
`extras-classicapi-bridge`, which adds normalized wrappers for macro spell
resolution, combat/focus verbs, debuff types, reach-aware unit range and
container item link/count data.

### Direct ClassicAPI-first modules

- **Bag Item Click** — modifier state and container hyperlink via the bridge.
- **Bag Search Bar** — container item ID/name/link via the bridge.
- **Macro Icons** — `GetActionInfo` and `GetMacroSpell` via the bridge.
- **Macro Tweaks** — container/item lookup plus `StartAttack`, `StopAttack`,
  `FocusUnit` and `ClearFocus` via the bridge.
- **Enable Raid Frames** — reach-aware `UnitInRange` and modifier state via
  the bridge.
- **Show Dispel Indicators** — normalized `GetDebuffType` via the bridge.
- **Show Bags** — Shift/Control state via the bridge.
- **Show Micro Menu** — Shift/Control state via the bridge.

### Indirect ClassicAPI-first module

- **Reagent Counter** uses the shared `ShaguTweaks.GetItemCount` helper. That
  helper now obtains stack counts, item IDs and item names through
  `ShaguTweaks.API`, so the module receives ClassicAPI container/item data
  without duplicating API logic locally.

### Modules intentionally remaining on native APIs

The other retained modules were checked individually. Their relevant operations
are FrameXML/UI functions or Vanilla game functions for which ClassicAPI does
not expose a replacement required by this addon:

- Dragonflight Gryphons
- Floating Actionbar
- Center Vertical Actionbar
- Center Text Input Box
- Enable Text Shadow
- Chat Timestamps
- Show Aggro Indicators
- Show Combat Feedback
- Use Compact Layout
- Show Group Headers
- Show Healing Predictions
- Hide Party Frames
- Use As Party Frames
- Reveal World Map

Examples include `CreateFrame`, anchoring/layout methods, chat-frame
`AddMessage`, `UseContainerItem`, `GetContainerNumSlots`,
`UnitHealth` / `UnitMana`, and WorldMap FrameXML functions. Replacing these
with invented wrappers would add abstraction without adding ClassicAPI value.

ClassicAPI does not currently expose an authoritative threat API, so
**Show Aggro Indicators** keeps its cached target/target-of-target heuristic.

### Central bridge additions

The paired ShaguTweaks-ClassicAPI branch adds:

- `API.GetMacroSpell`
- `API.StartAttack`
- `API.StopAttack`
- `API.FocusUnit`
- `API.ClearFocus`
- `API.GetDebuffType`
- `API.UnitInRange`
- `API.GetContainerItemLink`
- `API.GetContainerItemStackCount`

`API.UnitInRange` prefers ClassicAPI's reach-aware 40-yard implementation.
It explicitly handles the player's own frame and keeps the old interaction
check only as a centralized compatibility fallback.

`API.GetDebuffType` normalizes the different return layouts of
ClassicAPI's positional aura API and Vanilla 1.12 `UnitDebuff`, so Extras no
longer needs to branch on those signatures itself.

### Conversion result

No retained Extras module now performs its own ClassicAPI-versus-Vanilla
selection for the converted API families. That policy lives in
`ShaguTweaks.API`, matching the architecture of the main
ShaguTweaks-ClassicAPI fork.

## Second full counter-audit — 2026-08-30

A second audit was performed from the current branch state without assuming the
first audit was correct. This pass rechecked every retained module, cross-checked
the current ShaguTweaks-ClassicAPI tree, and specifically looked for load-order
bugs, stale UI state, first-frame initialization issues, hook ordering,
configuration interactions and unnecessary polling.

### Counter-audit result

**Static status: PASS with raid runtime validation still pending.**

The branch currently contains **23 Extras modules**. The current main
ShaguTweaks-ClassicAPI fork contains **48 modules**. The duplicate review was
repeated against the current main tree and did not reveal any additional module
that should be removed. Chat History and Energy Tick remain the only two
intentional duplicate removals.

The addon TOC references **32 Lua files and all 32 exist**. The four bundled TGA
assets used by retained modules are present, the eight locale files are harmless
empty stubs, and the original MIT license remains intact.

### New issues found and fixed during the second audit

#### Unordered ShaguTweaks module initialization

ShaguTweaks enables registered modules by iterating its module table with
`pairs()`, so module enable order must never be assumed.

The second audit found several hidden order dependencies:

- **Use As Party Frames** could return permanently when the base raid frame had
  not been enabled yet.
- **Hide Party Frames** had the same dependency.
- **Use Compact Layout** could access `ShaguTweaksRaidCluster.config` before
  the cluster existed.
- **Show Bags** and **Show Micro Menu** could read an uninitialized
  `Reduced Actionbar Size` configuration key on a fresh installation.

The raid core now exposes `ShaguTweaks.RaidFrame_OnReady(callback)`. Raid
submodules queue their initialization until the base raid frame exists, while
still executing immediately when it is already ready.

The reduced-actionbar companion modules now fall back to the main module's
declared default when its saved configuration key has not yet been initialized.

#### Raid component ordering

Ordered component and event lists now use `ipairs()` where order matters.
Base raid components are therefore always created in their defined order before
dependent Extras components such as Compact Layout, Combat Feedback and
Healing Predictions.

#### Deterministic first raid-frame state

Raid unit frames are created during `PLAYER_ENTERING_WORLD`. A newly-created
frame cannot safely rely on receiving the same event that caused it to be
created.

The base raid module now provides `ShaguTweaks.UnitFrame_Refresh(frame)` and
explicitly refreshes a frame immediately after assigning its raid/party unit.

Initial visual states are also explicit:

- target marker starts hidden
- combat highlight starts hidden
- aggro indicator starts hidden
- dispel indicators start hidden
- healing prediction starts hidden

This removes transient default-state artifacts while waiting for the next unit
event.

#### Raid group headers

Group Headers previously depended on receiving an event after their container
was created. The header module now waits only until all 40 raid-frame anchor
objects exist, performs an explicit first update, and then removes its temporary
`OnUpdate`.

It also updates on party changes so it behaves correctly when Raid Frames are
used as party frames.

Compact Layout no longer waits forever when Group Headers are disabled. When
headers are enabled it waits for an actual child header, not merely the header
container, and has a ten-second safety timeout.

#### Hide Party Frames visibility

Default PartyFrames are now hidden only while both the custom raid frame and
its cluster are visible. If the user manually hides the custom raid cluster,
the original PartyFrame `Show` methods are restored rather than leaving both
UIs hidden.

#### Healing prediction width

Incoming-heal width is recalculated on every shared 250 ms prediction tick
while a heal is active. Previously the width changed only when the incoming
heal amount changed, so player health changes could leave the predicted bar at
a stale width.

#### Reagent Counter stale slots

A slot that changed directly from a reagent-using spell to a non-reagent action
could retain its old reagent association. Full actionbar rescans now rebuild
the active reagent set, and occupied slots explicitly clear their previous
reagent when the tooltip contains no reagent requirement.

#### Floating Actionbar reputation anchors

`ReputationWatchBar` now clears its existing anchors before changing between
the XP-visible and XP-hidden positions. This prevents multiple constraints from
accumulating after reputation/XP state changes.

#### Chat wrapper ordering

**Chat Timestamps** and the main fork's **Chat Tweaks** both wrap
`ChatFrame.AddMessage`. Because module enable order is unordered, their wrapper
order could previously change between sessions.

Timestamp wrapping is now installed at `PLAYER_ENTERING_WORLD`, after the
normal ShaguTweaks module pass, giving a deterministic wrapper chain.

**Center Text Input Box** now uses the same strategy for its
`UIParent_ManageFramePositions` post-hook. This ensures it calculates its
position after Reduced Actionbar and other main-fork layout hooks have already
been installed.

#### Macro command ownership

`/equip` and `/use` now use the same collision-safe registration helper as
`/startattack`, `/stopattack`, `/focus` and `/clearfocus`. Macro Tweaks
therefore does not steal a slash command already registered by another addon.

#### World Map reveal state

The second pass removed dead overlay-hash/cache state that was not used to
render or compare map tiles.

Exploration marker frames now clear their previous anchors before being reused
on another zone map, and anonymous textures are used instead of empty-string
global texture names. Known native overlays are represented as simple boolean
membership data.

The current main fork's WorldMap Window, WorldMap Coordinates and WorldMap
Class Colors modules were cross-checked and do not replace
`WorldMapFrame_Update`, so they can coexist with Reveal World Map's safe
pre/post hooks.

### Configuration interaction review

- **Hide Gryphons + Dragonflight Gryphons:** safe. Hide Gryphons takes
  precedence because Dragonflight Gryphons changes textures but never forces a
  hidden endcap to show.
- **Floating Actionbar + Reduced Actionbar Size:** compatible. Their shared
  reputation/actionbar layout interaction is now anchor-safe.
- **Show Bags / Show Micro Menu + Reduced Actionbar Size:** intentionally
  coupled. The Extras modules restore the native `Show` method that Reduced
  Actionbar deliberately suppresses, then reparent those controls to their own
  panels.

### Remaining intentional global wrappers

The second audit again reviewed every remaining direct wrapper. These are kept
because the feature must intercept rather than merely observe the call:

- `UseContainerItem` — Bag Item Click can redirect the action to trade/AH.
- `SendChatMessage` — Macro Tweaks suppresses `#showtooltip` metadata that
  Vanilla would otherwise send to chat.
- `ChatFrameEditBox.AddHistoryLine` — prevents executed macro commands from
  polluting typed-command history.
- `ChatFrame.AddMessage` — Chat Timestamps must alter displayed text.
- PartyMemberFrame `Show` — temporarily suppressed while the custom raid UI is
  actually visible and restored afterwards.

No retained module directly replaces `WorldMapFrame_Update`,
`UIParent_ManageFramePositions`, `ReputationWatchBar_Update` or
`GameTooltip.SetBagItem`.

### Remaining OnUpdate review

Every retained `OnUpdate` was reviewed again:

- **Reagent Counter:** frame is hidden while idle and wakes for one processing
  frame after relevant events.
- **Show Bags / Show Micro Menu:** 50 ms modifier/mouse polling used only for
  the Ctrl+Shift drag interaction.
- **Raid shared ticker:** one 250 ms ticker services periodic raid components.
- **Raid toggle drag:** installed only while the user is actively dragging.
- **Group Headers:** temporary one-shot initialization waiter, removed as soon
  as all raid anchors exist.
- **Compact Layout:** temporary header waiter with a ten-second hard stop.
- **Combat Feedback:** per-visible-unit frame animation remains intentionally
  unchanged pending real raid profiling.

### Runtime-only risks still open

Two areas require a real populated raid before they should be optimized further:

1. **Combat Feedback** uses Blizzard's `CombatFeedback_OnUpdate` animation and
   therefore retains per-visible-unit frame updates. Replacing that animation
   without runtime testing would be higher risk than leaving it intact.
2. **Aggro Indicator** uses a Vanilla-compatible heuristic that checks targets
   and target-of-target relationships across group/raid unit tokens. It is
   cached for one second per displayed unit, but a 20/40-player raid is still
   required to measure its actual cost.

These are not currently identified correctness bugs. They are explicit
performance validation targets.

### Current runtime validation status

Macro Tweaks / Macro Icons received live fixes and retesting for:

- `/startattack`
- bare `#showtooltip`
- `#showtooltip Spell`
- automatic macro spell icon resolution

Those cases are now behaving correctly in the test client.

Raid functionality remains **runtime-unvalidated**. The branch should therefore
stay a draft test candidate until at least a small converted raid has exercised
frame creation, roster changes, party-frame restoration, dispels, predictions
and combat feedback.

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

The tooltip scan is unavoidable because ClassicAPI does not expose the reagent
requirements needed for this action-button feature. Item counting itself is now
ClassicAPI-first indirectly through the shared `ShaguTweaks.GetItemCount`
helper. Previously an `OnUpdate` ran permanently and all 120 action slots were
rescanned after every bag event.

Now the frame sleeps while idle. Action-layout events request a one-frame
tooltip rescan; `BAG_UPDATE` only refreshes counts for reagents already known.
Button and count-font accesses are also nil-guarded.

#### Center Vertical Actionbar — retained

Simple one-time frame positioning. No ClassicAPI benefit and no hot-path work.

#### Show Bags — fixed / optimized

Uses the shared ClassicAPI-first modifier helpers directly. Modifier polling is throttled to 50 ms.
Initialization is guarded against repeated `PLAYER_ENTERING_WORLD` work.
Child anchors are cleared before reparenting.

The old `frame.Show = frame:Show()` trick was replaced by the explicit
`frame.Show = nil` restoration followed by the native `:Show()` method.

#### Show Micro Menu — fixed / optimized

Same hardening as Show Bags. The configured `panelmicro.scale` value was
previously defined but never applied; it is now used.

### Bags / General

#### Bag Item Click — hardened

Shift state and auction-browser container links now go through the shared ClassicAPI-first bridge.

The old replacement of `GameTooltip.SetBagItem` was removed and replaced by a
safe post-hook.

The `UseContainerItem` interception remains intentionally global because this
feature must be able to suppress the default item use while trade/auction
actions are active. The original function is preserved and called for the
normal path.

#### Bag Search Bar — fixed / ClassicAPI-aware

Fixed a possible nil dereference where the icon texture was read before the bag
button had been validated.

Item IDs/names now use `ShaguTweaks.API.GetContainerItemID` and
`GetItemNameByID` directly. Hyperlink fallback also goes through
`API.GetContainerItemLink`, which prefers ClassicAPI container data and keeps
the Vanilla fallback centralized. This improves compatibility with ClassicAPI
item caches and custom Turtle items.

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

Uses `ShaguTweaks.API.GetActionInfo` directly to resolve macro action IDs.

Fixed an action-slot bug: the old code fetched the fallback texture using the
local button index instead of the real paged action slot. This was wrong on
paged/bonus bars.

Macro bodies are now cached once per actionbar event instead of scanning all 36
macro slots again for every button.

`#showtooltip Spell` retains explicit priority. A bare `#showtooltip` now
uses ClassicAPI's O(1) `GetMacroSpell(macroSlot)` result, matching the expected
modern behavior where the first resolved cast supplies the icon/tooltip.
The old text parser remains as fallback for stale macro caches and `/pfcast`.
`UPDATE_MACROS` now triggers an immediate action-button rescan after editing a
macro.

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

Container item lookup, macro combat/focus verbs and item metadata now go
through the shared ClassicAPI-first bridge.

Numeric `/use` and `/equip` parsing is anchored so arbitrary item names that
contain digits are not accidentally interpreted as inventory slots.

The `SendChatMessage` interception and edit-box history wrapper remain
intentional because these features must suppress macro metadata/history rather
than merely observe calls. The metadata filter now handles both
`#showtooltip Spell` and a bare `#showtooltip` line (including surrounding
whitespace), so the latter can no longer leak into chat.

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
- range checks use `API.UnitInRange`, preferring ClassicAPI's reach-aware
  40-yard implementation with fallback centralized in the bridge
- undefined health-bar alpha replaced with explicit `1`
- unknown mana power types have a safe fallback color
- compact layout is handled directly by the base text component
- raid-toggle drag `OnUpdate` exists only while actually dragging
- ClassicAPI-first Shift detection is used for dragging

#### Use As Party Frames — hardened

The wrapped raid event handler is now nil-guarded before invocation.

#### Show Group Headers — retained

Event-driven and low cost. No ClassicAPI-specific data required.

#### Show Combat Feedback — optimized

Explicitly marked as the only default raid component requiring frame-by-frame
animation. Removed unnecessary globally named FontString creation and fixed the
frame reference used by the UNIT_COMBAT filter.

#### Show Dispel Indicators — ClassicAPI-aware

Uses the normalized `API.GetDebuffType` bridge. ClassicAPI's positional aura
API is preferred and the different Vanilla 1.12 return layout is handled only
inside the central bridge.

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

# ShaguTweaks-Extras-ClassicAPI third-party notices

This file records third-party material, upstream sources, external runtime
dependencies, and compatibility references known to ShaguTweaks-Extras-ClassicAPI.

It is intentionally additive: source comments, Git history, `AUDIT.md`,
upstream license notices, and README credits remain part of the provenance trail
and should not be removed merely because this summary exists.

## ShaguTweaks-extras

ShaguTweaks-Extras-ClassicAPI is a fork of the ShaguTweaks-extras tree maintained
by paokkerkir:

- Source: https://github.com/paokkerkir/ShaguTweaks-extras
- Upstream license notice: MIT
- Copyright (c) 2025 Eric Mauser (Shagu)

The original MIT license remains at the repository root in `LICENSE` and an
additional preserved copy is stored in
`LICENSES/ShaguTweaks-extras-MIT.txt`.

The MIT grant applies to material for which the applicable upstream copyright
holder had the right to grant those permissions. It does not by itself
establish ownership or relicensing authority over unrelated third-party or
game-derived assets that may have been present in an upstream package.

## TokensWorth/ShaguTweaks-mods

The following modules in this fork contain code adapted from
`TokensWorth/ShaguTweaks-mods`:

- `mods/actionbar-mouseover-common.lua`
- `mods/actionbar-mouseover-bar-right.lua`
- `mods/actionbar-mouseover-bar-right2.lua`
- `mods/actionbar-hide-macro.lua`
- `mods/unitframes-abbrev-names.lua`
- `mods/cursor-tooltip.lua`
- `mods/hide-combat-tooltip.lua`

Source:
- https://github.com/TokensWorth/ShaguTweaks-mods

License: MIT
Copyright (c) 2022 GryllsAddons

The preserved upstream license text is stored in
`LICENSES/ShaguTweaks-mods-MIT.txt`.

## ShaguTweaks-ClassicAPI

ShaguTweaks-ClassicAPI is a required external addon dependency used by this
Extras fork.

- Source: https://github.com/Dusk-92/ShaguTweaks-ClassicAPI
- It is **not bundled** inside this repository.
- Its MIT license notice is preserved in
  `LICENSES/ShaguTweaks-ClassicAPI-MIT.txt` for reference.

This dependency relationship does not merge the two repositories into a single
distribution and does not imply that every notice in one repository applies to
the other.

## ClassicAPI

ClassicAPI is a required external runtime dependency used through the shared
`ShaguTweaks.API` compatibility layer.

- Source: https://github.com/brues-code/ClassicAPI
- The upstream repository includes the GNU General Public License version 3.
- ClassicAPI itself is **not bundled** in this addon repository.

A verbatim copy of the upstream license document is preserved in
`LICENSES/ClassicAPI-GPL-3.0.txt` for reference. Including that license text
does not relicense ShaguTweaks-Extras-ClassicAPI under the GPL and does not
imply that ClassicAPI binaries or source are distributed as part of this addon.

## SuperWoW

SuperWoW is an optional external runtime dependency used indirectly through
ShaguTweaks-ClassicAPI compatibility paths.

- Source: https://github.com/balakethelock/SuperWoW
- SuperWoW is **not bundled** in this repository.
- Its upstream license is preserved verbatim in
  `LICENSES/SuperWoW-LICENSE.txt`.

The upstream SuperWoW license has its own restrictions. This notice records the
dependency and preserves its license; it does not extend those terms to
ShaguTweaks-Extras-ClassicAPI or grant additional rights in SuperWoW.

## Turtle WoW-like environments

ShaguTweaks-Extras-ClassicAPI contains compatibility logic intended for
Turtle WoW-like server/client environments. Compatibility, testing, naming, or
behavioral reference does not create an affiliation, endorsement, partnership,
or ownership relationship with those projects or their maintainers.

## Artwork and screenshots

Artwork under `img/` and screenshots under `screenshots/` are tracked
separately in `Docs/ASSET_PROVENANCE.md`.

At the time of the 2026-08-31 provenance audit, the complete `img/` and
`screenshots/` trees were byte-identical, at Git object level, to the
corresponding directories in `paokkerkir/ShaguTweaks-extras`.

A project-level software license does not automatically prove ownership or
relicensing authority for every visual asset in an upstream project. The asset
manifest therefore records exact upstream matches without making broader
ownership claims.

## Project identity and trademarks

The canonical repository maintained by Dusk-92 is:

- https://github.com/Dusk-92/ShaguTweaks-Extras-ClassicAPI

Forks, mirrors, package caches, and modified copies hosted elsewhere are
independent unless this canonical project explicitly states otherwise.

World of Warcraft and Blizzard Entertainment names, marks, and game assets
remain the property of their respective rights holders. Other project names and
trademarks remain the property of their respective owners.

See `PROJECT_IDENTITY.md` for the full project-identity notice.

## Preservation rule

Do not remove historical source comments, attribution notes, license notices,
audit notes, compatibility explanations, or provenance records simply because
newer documentation summarizes them.

When replacing or substantially rewriting third-party-derived material, update
the provenance record rather than erasing the earlier history.

# ADR 0001 — Drop the hex overlay in favor of a side panel

- **Status**: Accepted
- **Date**: 2026-04-19
- **Affects**: `v2.0.0`

## Context

`v1.0.0` through `v1.0.3` shipped with a single layout: a **hexagonal overlay** rendered on top of the minimap. Clicking the trigger dimmed the minimap to 40 % alpha and reparented the collected addon buttons into a hex-packed grid centered on the minimap. Closing restored them.

The design worked technically, but a review across the category after the first real-user session surfaced two issues:

1. **Covering the minimap is an UX anti-pattern in this category.** Of the five most-installed addons that group minimap buttons — MinimapButtonButton (~13.9M downloads), HidingBar (~5M), MinimapButtonFrame (~1.6M), MinimapButtonBag Reborn (~1.4M), Chinchilla (~1.9M) — **none** cover the minimap. They all expand into a side popup, a separate movable frame, or use hover-hide. The jobs-to-be-done of players who install this category of addon include reading the minimap during raids, battlegrounds, and quest navigation. Covering the map during those moments contradicts the primary use-case of the minimap itself.
2. **Hex packing does not scale past ~15 buttons.** The breathing-room constant that made the grid readable for small setups overflows the minimap's footprint once an installation has 20–30 addons with minimap buttons — which is exactly the installation type that benefits most from this addon. GitHub issues in neighbouring projects also report multi-second lag at those counts; our hex implementation would have had a similar ceiling.

The unique visual of the hex overlay was genuine product differentiation, but the trade-off became "a novel aesthetic that the target audience can't use comfortably."

## Decision

Remove the hex overlay layout entirely as of `v2.0.0`. The single supported layout is a **side panel grid** anchored to a configurable corner of the minimap, rendered as an ordinary floating frame that does not touch the minimap's alpha. The hex code is deleted from the active codebase; no layout abstraction, no dropdown in settings, no opt-in path.

The design decision is documented here so that future contributors understand why a seemingly valuable feature was removed rather than left in as an option.

## Consequences

### Positive

- **Scope reduction of ≈200 LOC in v2.** Removing the hex layout, the would-be layout abstraction, and the settings dropdown that would have toggled between them cuts roughly a quarter of the original v2 scope, freeing budget for the features actually requested by users (per-button hide, reorder, search, Masque).
- **Every subsequent feature has a single target surface.** Per-button hide, reorder, search, and Masque skinning each need to work with only one layout, halving design and test effort.
- **Eliminates the `Minimap:SetAlpha` / ElvUI interaction at the root.** The alpha manipulation that made hex visible was also the source of a predictable conflict with any addon that reskins the minimap. Side panel is an independent frame; there is nothing to conflict with.
- **Clearer product positioning.** "One trigger, one clean panel" is easier to explain and easier to reason about than a menu of layouts.

### Negative

- **A genuinely unique visual is retired.** The hex overlay is, to our knowledge, the only such rendering in the category. Future users who might have preferred the aesthetic lose the option.
- **Existing v1 users experience a visible behavior change.** The first launch of `v2.0.0` prints a one-shot chat notice explaining the change. The user base is small enough at the point of this decision that the disruption is minimal; documentation (`CHANGELOG.md`, `README.md`) covers the rest.

### Reversibility

The hex implementation is preserved in git history on the `v1.0.3` tag and earlier. If a future `v3.x` reintroduces alternative layouts — for example because a meaningful fraction of users request the old aesthetic with concrete data — a layout abstraction can be designed then against that data, rather than speculatively in v2.

## References

- Source research (GitHub issues, CurseForge/Wago comments, Reddit threads) gathered on 2026-04-19, summarized in the project plan at the time of this ADR.
- Competing addons surveyed: [MinimapButtonButton](https://www.curseforge.com/wow/addons/minimapbutton), [HidingBar](https://www.curseforge.com/wow/addons/hidingbar), [Minimap Button Frame](https://www.curseforge.com/wow/addons/minimap-button-frame), [MinimapButtonBag Reborn](https://www.curseforge.com/wow/addons/minimapbuttonbag-reborn-mmb-reborn), [Chinchilla](https://www.curseforge.com/wow/addons/chinchilla).

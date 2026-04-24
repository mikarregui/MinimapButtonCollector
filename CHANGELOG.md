# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.1] - 2026-04-24

### Fixed

- **Excluded LibDBIcon buttons now return to the minimap.** When a button was unchecked in the Collected buttons settings section (or excluded via `/mbc exclude`) after having been placed in the panel, it could stay "glued" to its panel-grid position instead of re-anchoring to its minimap angle. `ReleaseButton` now clears all points and resets the frame strata before delegating to `LibDBIcon-1.0:Show`, so the library's `CENTER → Minimap` anchor is the only one active after release. Non-LibDBIcon (legacy `minimap-child`) buttons were not affected — that code path already cleared points explicitly.

## [2.1.0] - 2026-04-24

### Added

- **Per-button exclusion** — individual addon buttons can be kept on the minimap instead of being collected into the panel. Useful when an icon communicates state at a glance (e.g. a gear-manager button showing the equipped set) and only makes sense as a permanent presence on the minimap. Toggled from the new **Collected buttons** section in `/mbc config` or via `/mbc exclude <ButtonName>` / `/mbc include <ButtonName>`. Per-character.
- **Per-button reorder** — `▲` / `▼` arrows on each row of the Collected buttons settings section swap the button's position inside the panel. Arrows at the extremes are disabled so clicks never produce a no-op move. Per-character, persists across reloads.
- **Collected buttons settings section** — scrollable list of every detected button with a "Collect in panel" checkbox + reorder arrows + button name. Excluded entries appear below the collected ones (alphabetical) so re-enabling them is a single click away.

### Changed

- Internal: the unused `perChar.hiddenButtons` stub left by v2.0.0 is renamed to `excludedButtons` (and the empty v2.0.0 field is dropped during migration). New `perChar.buttonOrder` stores the panel ordering. No schema version bump — all handled in the existing idempotent `migrateSavedVariables`.

## [2.0.0] - 2026-04-19

### ⚠ Breaking changes

- **Hex overlay removed.** The overlay no longer covers the minimap. The single supported layout is now a **side panel** anchored to a configurable corner of the minimap. Full rationale in [docs/adr/0001-drop-hex-overlay-in-favor-of-side-panel.md](docs/adr/0001-drop-hex-overlay-in-favor-of-side-panel.md).
- **SavedVariables schema bumped to v2.** The trigger position moves from the global DB (`MinimapButtonCollectorDB.minimap`) to a new per-character DB (`MinimapButtonCollectorPerCharDB`), so each of your characters keeps its own trigger angle. Your existing v1 angle is migrated automatically on first v2 login; a backup of the v1 DB is preserved under `MinimapButtonCollectorDB._legacy_v1` just in case.
- **One-shot chat message** on the first v2 login announces the layout change and points at `/mbc config`.

### Added

- **Side panel layout** — grid anchored to a chosen corner of the minimap with a thin gold border and a subtle warm fill (pale gold at 15 % alpha). Six anchor presets: `LEFT`, `RIGHT`, `BOTTOMLEFT`, `BOTTOMRIGHT`, `TOPLEFT`, `TOPRIGHT`. Button count auto-sizes the grid. The fill is lighter than both the icons and the world behind, so mixing it in *raises* pixel luminance rather than lowering it — icons stand out against the panel rather than being dimmed by contrast.
- **Settings panel** — `/mbc config` (or right-click the trigger) opens a standalone floating settings window. v2.0.0 exposes the panel anchor, the "close on outside click" toggle, and an About section with version, distribution links, and Ko-fi. Per-button hide/reorder land in v2.1.0; search in v2.2.0; Masque in v2.3.0.
- **"Close panel when clicking outside"** toggle in settings, default **ON**. Click anywhere outside the panel and it closes; disable in settings for a more WoW-native non-modal behavior.
- `## SavedVariablesPerCharacter: MinimapButtonCollectorPerCharDB` in the `.toc`.
- `docs/adr/` directory with the first Architecture Decision Record explaining why hex was dropped.
- README: new Compatibility section covering ElvUI; roadmap restructured around the v2.x versions.
- `/mbc debug <ButtonName>` diagnostic command — dumps per-region info (type, layer, size, alpha, vertex colour, texture id, shown state) for a collected button. Useful for reporting visual issues with unusual addon buttons.

### Changed

- **Default panel anchor is `LEFT`** (panel to the left of the minimap) — natural placement when the minimap is in the top-right corner of the screen (TBC default), leaves the map itself fully visible and lets the panel grow downward.
- Fade transition animates only the side panel and its contained buttons; the minimap itself is no longer touched (no `Minimap:SetAlpha` anywhere in the addon). This removes a whole class of conflicts with ElvUI and other addons that skin the minimap.
- Grid pitch is sized to fit LibDBIcon's ~53 px tracking border without adjacent rings overlapping — each collected button keeps its native minimap-button framing (ring + inner disc + icon) instead of being stripped of decorations.
- `/mbc rescan` is now documented as rarely needed: late LibDBIcon registrations have been captured live since v1.0.3 via a `hooksecurefunc` on `LibDBIcon:Register`.

### Fixed

- Collected LibDBIcon buttons no longer look desaturated inside the panel. Earlier iterations tried hiding their decorative textures; real-user smoke testing showed the actual cause was the dark panel backdrop reducing perceived icon saturation by visual contrast. The shipping fix keeps each button's native framing intact (tracking ring + background disc + icon) and pairs a slightly wider grid pitch with a thin gold border plus a pale warm fill at low alpha — the fill's higher luminance makes icons stand out *more* against the panel, not less.

### Removed

- `UI.lua` hex-packing math, `overlayHost` frame, and `Minimap:SetAlpha` dim transition — all superseded by the side panel.

## [1.0.3] - 2026-04-19

### Added
- Press **ESC** to close the overlay — the standard WoW way. The overlay registers a tiny proxy frame in `UISpecialFrames`; WoW hides it when Escape is pressed and our `OnHide` handler runs the normal animated close.
- Live capture of LibDBIcon buttons registered after the initial post-login scans. We now post-hook `LibDBIcon-1.0:Register` via `hooksecurefunc`, so any addon that creates its minimap button late (e.g. only when you open a raid frame or enter a group) is adopted the moment it registers — `/mbc rescan` is rarely needed anymore.

### Changed
- README now shows a CurseForge downloads badge alongside the existing GitHub badge and calls out the three distribution channels (GitHub Releases, CurseForge, Wago) right under the badges so the availability is obvious at a glance.
- `.github/FUNDING.yml` added with a Ko-fi link, so the GitHub repo sidebar now has a "Sponsor" button. Matching compact `## Support` section at the end of the README. Strictly opt-in for users — nothing in-game ever prompts for donations.

## [1.0.2] - 2026-04-19

### Added
- Published on Wago at https://addons.wago.io/addons/minimapbuttoncollector via Wago's GitHub Addon integration — no `X-Wago-ID` header or upload token needed; Wago pulls releases from GitHub automatically.

### Fixed
- README logo image now uses an absolute `raw.githubusercontent.com` URL so it renders correctly on external sites that embed the README (Wago project page, mirrors, etc.). The previous relative path worked on github.com but broke everywhere else.
- `assets/` folder is no longer packaged inside the addon ZIP. The logo lives there for CurseForge / Wago / README header use; it doesn't need to ship to the user's AddOns folder. The v1.0.1 ZIP was ~7 KB heavier than necessary for this reason.

## [1.0.1] - 2026-04-19

### Added
- Published on CurseForge at https://www.curseforge.com/wow/addons/minimap-button-collector. Releases tagged from this version onward upload to CurseForge automatically via the packager (uses the `CF_API_KEY` repository secret and the `X-Curse-Project-ID` header in the `.toc`).
- Project logo committed at `assets/logo.png` and displayed at the top of the README.

### Fixed
- README no longer describes pre-rc5 behavior: the Features list no longer claims the overlay refuses to open in combat (it can), and the Usage section no longer mentions closing on a click outside the minimap (the overlay has been non-modal since v1.0.0).

## [1.0.0] - 2026-04-19

Initial public release.

### Added
- Repository scaffolding: README with badges, CONTRIBUTING, LICENSE (MIT), `.editorconfig`, `.gitignore`, `.pkgmeta`, GitHub issue / PR templates, BigWigs Packager release workflow.
- Minimap Button Collector addon — groups minimap addon buttons under a single draggable trigger. Click the trigger to dim the minimap and reveal the collected buttons as a hex-packed overlay on top of it; click any button to run its action and auto-close the overlay.
- Hybrid button detection — iterates `LibDBIcon-1.0` registered objects first, then falls back to scanning `Minimap:GetChildren()` with a Blizzard-frame blacklist, a dynamic-indicator name filter (`*Frame\d+`, `*Icon\d+`, `*Pin\d+`, `*Marker\d+`), and a 18–48 px size window.
- Adopted buttons are hidden outside the overlay via a per-button `Show` override, so only the MBC trigger remains on the minimap edge in idle state.
- Dedicated `MBCOverlayHost` frame anchored to the minimap but parented to `UIParent`, so the 40 % minimap dim during open state does not propagate to the buttons — they render at full opacity.
- Non-modal behavior — world interactions (looting, NPC clicks, spells, action bars) remain active while the overlay is open. The overlay can also be opened and kept open during combat.
- 8 px gap between buttons horizontally and vertically for readable spacing.
- Conflict skip for buttons already managed by MoveAny, SexyMap, or Chinchilla (with a chat warning).
- Slash commands: `/mbc` (toggle), `/mbc rescan` (re-detect), `/mbc list` (summary grouped by source, up to 10 names per source), `/mbc list full` (full dump).
- Automated GitHub Releases via BigWigs Packager on tag push, resolving LibStub / CallbackHandler-1.0 / LibDataBroker-1.1 / LibDBIcon-1.0 externals from `.pkgmeta`.

[Unreleased]: https://github.com/mikarregui/MinimapButtonCollector/compare/v2.1.1...HEAD
[2.1.1]: https://github.com/mikarregui/MinimapButtonCollector/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/mikarregui/MinimapButtonCollector/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/mikarregui/MinimapButtonCollector/compare/v1.0.3...v2.0.0
[1.0.3]: https://github.com/mikarregui/MinimapButtonCollector/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/mikarregui/MinimapButtonCollector/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/mikarregui/MinimapButtonCollector/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/mikarregui/MinimapButtonCollector/releases/tag/v1.0.0

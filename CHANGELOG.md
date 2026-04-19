# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/mikarregui/MinimapButtonCollector/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/mikarregui/MinimapButtonCollector/releases/tag/v1.0.0

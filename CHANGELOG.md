# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository scaffolding: README, CONTRIBUTING, LICENSE (MIT), `.editorconfig`, `.gitignore`, `.pkgmeta`, GitHub issue/PR templates, BigWigs Packager release workflow.
- Minimap Button Collector addon MVP — hybrid detection (LibDBIcon + Minimap children with Blizzard blacklist), on-minimap hex overlay with 200ms fade, auto-close, draggable trigger, `/mbc`, `/mbc rescan`, `/mbc list`.

### Fixed
- Minimap-children scan no longer adopts dynamic indicator frames (e.g. `QuestieFrameN`, other `*Frame\d+`, `*Icon\d+`, `*Pin\d+`, `*Marker\d+` named pins) that clutter the overlay with hundreds of quest POI markers on heavy setups. Detection now also enforces a 18–48 px size window, the typical range for real minimap buttons.
- Adopted buttons are now hidden outside the overlay — only the MBC trigger remains visible at the minimap edge. The owning addon's `Show` is overridden with a no-op at adoption time so its own code can't re-show the button; the overlay uses the saved original to display buttons when opened.
- Buttons in the open overlay are no longer dimmed along with the minimap. They now live on a dedicated `MBCOverlayHost` frame anchored to the minimap but parented to `UIParent`, so `Minimap:SetAlpha(0.4)` no longer propagates to them and they render at full opacity over the dimmed map.

### Changed
- `/mbc list` now summarizes collected buttons grouped by source (LibDBIcon / minimap-child) and shows up to 10 names per source. Full dump available via `/mbc list full`.

[Unreleased]: https://github.com/mikarregui/MinimapButtonCollector/compare/HEAD...HEAD

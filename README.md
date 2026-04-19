<p align="center">
  <img src="https://raw.githubusercontent.com/mikarregui/MinimapButtonCollector/main/assets/logo.png" alt="Minimap Button Collector logo" width="160">
</p>

# MinimapButtonCollector

> One trigger button on your minimap. Click it, all your addon buttons fan onto the minimap itself. Click one, it closes. Done.

[![Release](https://img.shields.io/github/v/release/mikarregui/MinimapButtonCollector?sort=semver&display_name=tag)](https://github.com/mikarregui/MinimapButtonCollector/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub downloads](https://img.shields.io/github/downloads/mikarregui/MinimapButtonCollector/total.svg?label=GitHub&color=24292f)](https://github.com/mikarregui/MinimapButtonCollector/releases)
[![CurseForge downloads](https://img.shields.io/curseforge/dt/1518595?label=CurseForge&color=f16436)](https://www.curseforge.com/wow/addons/minimap-button-collector)
[![Issues](https://img.shields.io/github/issues/mikarregui/MinimapButtonCollector.svg)](https://github.com/mikarregui/MinimapButtonCollector/issues)
[![Stars](https://img.shields.io/github/stars/mikarregui/MinimapButtonCollector.svg?style=social)](https://github.com/mikarregui/MinimapButtonCollector/stargazers)

> Target client: **World of Warcraft — The Burning Crusade Classic Anniversary Edition** (2.5.5, Interface `20505`).
> Available on **[GitHub Releases](https://github.com/mikarregui/MinimapButtonCollector/releases)**, **[CurseForge](https://www.curseforge.com/wow/addons/minimap-button-collector)**, and **[Wago](https://addons.wago.io/addons/minimapbuttoncollector)**.

<!-- TODO: add demo GIF here after first release -->

## Why

Install a handful of addons and your minimap edge turns into a ring of overlapping little buttons. Finding the one you want becomes a game in itself. MinimapButtonCollector reclaims that space: a single trigger sits on the minimap, and when you click it, all the collected addon buttons fan onto the minimap itself in a clean hexagonal layout.

## Features

- **Hybrid detection** — catches modern LibDBIcon buttons (including those registered after login, captured live) and legacy minimap buttons
- **On-minimap overlay** — buttons appear on top of the minimap, not in a floating panel
- **Smooth fade transition** — minimap dims, buttons appear, feels native
- **Auto-close** — click any addon button and the overlay closes on its own
- **Draggable trigger** — move it anywhere around the minimap edge
- **Non-modal** — the overlay coexists with world interactions (loot, NPCs, spells) and can be opened or kept open during combat
- **Zero config** — install and it works

## Installation

### Via addon manager (recommended)

Available on [CurseForge](https://www.curseforge.com/wow/addons/minimap-button-collector) and [Wago](https://addons.wago.io/addons/minimapbuttoncollector). Install via the CurseForge app, the Wago app, or [WowUp](https://wowup.io) (multi-source).

### Manual

1. Download the latest `MinimapButtonCollector-vX.Y.Z.zip` from the [Releases page](https://github.com/mikarregui/MinimapButtonCollector/releases).
2. Extract the `MinimapButtonCollector/` folder into your AddOns directory:
   ```
   <WoW install>\_anniversary_\Interface\AddOns\
   ```
3. Launch WoW. Enable the addon in the AddOns menu if needed. `/reload` in-game.

## Usage

- **Click** the trigger button on the minimap → overlay opens.
- **Click any button** in the overlay → addon action runs, overlay closes.
- **Re-click the trigger** or press **ESC** → overlay closes.
- **Drag the trigger** around the minimap edge to reposition it. Position persists.

### Slash commands

| Command | Action |
|---|---|
| `/mbc` | Toggle overlay open/closed |
| `/mbc rescan` | Re-detect minimap buttons (use if an addon loaded late) |
| `/mbc list` | Print a summary of collected buttons grouped by source |
| `/mbc list full` | Print the full list of collected buttons (debug) |

## Development

This repo is set up for serious iteration. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

### Quick start

```bash
git clone https://github.com/mikarregui/MinimapButtonCollector.git
cd MinimapButtonCollector
```

Symlink the addon folder into your WoW install (PowerShell as Administrator):

```powershell
New-Item -ItemType SymbolicLink `
  -Path "C:\BattleNet\World of Warcraft\_anniversary_\Interface\AddOns\MinimapButtonCollector" `
  -Target "$PWD\MinimapButtonCollector"
```

Then edit in the repo, `/reload` in-game, iterate.

### How releases are built

Push a tag `vX.Y.Z` to `main`. The [BigWigs Packager](https://github.com/BigWigsMods/packager) GitHub Action resolves library externals, injects the version into the `.toc`, and publishes a ZIP to GitHub Releases. No manual packaging step.

## Roadmap

Planned for future versions:

- Hide/show individual buttons from the overlay
- Editable blacklist (exclude specific addon buttons)
- Drag & drop reorder inside the overlay
- Search / filter by name

## Tech stack

- **Lua 5.1** (the version WoW's client runs)
- [LibStub](https://www.wowace.com/projects/libstub)
- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler)
- [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1)
- [LibDBIcon-1.0](https://www.wowace.com/projects/libdbicon-1-0)
- [BigWigs Packager](https://github.com/BigWigsMods/packager) for release automation

## Support

If **Minimap Button Collector** saves you some minimap real estate and you feel like saying thanks, you can tip me a coffee on Ko-fi. Completely optional — the addon stays free and fully functional regardless.

[![Ko-fi](https://img.shields.io/badge/Ko--fi-tip%20me-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/mikarregui)

## License

[MIT](LICENSE) © mikarregui

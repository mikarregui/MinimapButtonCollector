<p align="center">
  <img src="https://raw.githubusercontent.com/mikarregui/MinimapButtonCollector/main/assets/logo.png" alt="Minimap Button Collector logo" width="160">
</p>

# MinimapButtonCollector

> One trigger on your minimap. Click it, your addon buttons appear in a clean side panel. Click one, it closes. Done.

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

Install a handful of addons and your minimap edge turns into a ring of overlapping little buttons. Finding the one you want becomes a game in itself. MinimapButtonCollector reclaims that space: a single trigger sits on the minimap, and when you click it, all the collected addon buttons appear in a clean side panel anchored to the minimap.

## Features

- **Hybrid detection** — catches modern LibDBIcon buttons (including those registered after login, captured live) and legacy minimap buttons
- **Side panel layout** — buttons appear in a floating panel anchored to a configurable corner of the minimap. Never covers the map itself, so raid / BG / quest navigation stays readable
- **Per-button exclusion** — keep individual buttons on the minimap instead of collecting them, ideal for icons whose look communicates state at a glance
- **Reorder inside the panel** — arrange collected buttons in the order that makes sense for you, per character
- **Smooth fade transition** — 200 ms panel fade, no jarring pop-in
- **Auto-close** — click any addon button and the panel closes on its own
- **Draggable trigger** — move it anywhere around the minimap edge; position persists per-character
- **Non-modal** — the panel coexists with world interactions (loot, NPCs, spells) and can be opened or kept open during combat
- **Native settings** — `/mbc config` or right-click the trigger opens a Blizzard-style settings panel

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

- **Click** the trigger button on the minimap → side panel opens.
- **Click any button** in the panel → addon action runs, panel closes.
- **Re-click the trigger** or press **ESC** → panel closes.
- **Right-click the trigger** → settings panel.
- **Drag the trigger** around the minimap edge to reposition it. Position persists per-character.

### Slash commands

| Command | Action |
|---|---|
| `/mbc` | Toggle the side panel |
| `/mbc config` | Open the settings panel |
| `/mbc exclude <ButtonName>` | Keep a specific button on the minimap (never collect it). Case-sensitive — use `/mbc list` to see exact names |
| `/mbc include <ButtonName>` | Undo an exclusion; the button goes back into the panel |
| `/mbc rescan` | Re-detect minimap buttons (rarely needed — new LibDBIcon buttons are captured live) |
| `/mbc list` | Print a summary of collected buttons grouped by source |
| `/mbc list full` | Print the full list of collected buttons (debug) |

## Compatibility

The side panel is an independent frame anchored to the minimap via `SetPoint`. It does not manipulate the minimap's alpha or reparent Blizzard frames, so it coexists cleanly with ElvUI minimap skinning and other addons that reshape the minimap.

## Development

This repo is set up for serious iteration. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow. Architectural decisions are recorded in [docs/adr/](docs/adr/).

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

Planned:

- Search / filter at the top of the panel
- [Masque](https://www.curseforge.com/wow/addons/masque) skin support

Future ideas: drag & drop reorder inside the panel, additional layout options if users ask for them with data.

## Tech stack

- **Lua 5.1** (the version WoW's client runs)
- [LibStub](https://www.wowace.com/projects/libstub)
- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler)
- [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1)
- [LibDBIcon-1.0](https://www.wowace.com/projects/libdbicon-1-0)
- [BigWigs Packager](https://github.com/BigWigsMods/packager) for release automation

## Support

Open an issue on GitHub if you spot something off — `/mbc list full` or `/mbc debug <ButtonName>` gives me the context I need.

### Tip jar ☕

If this addon saves you some minimap real estate, consider buying me a coffee. Entirely optional — the addon is free and stays free.

When tipping, you can optionally leave your in-game name + server (or GitHub handle) and I'll add you to a supporters list in the next release. Anonymous tips are just as welcome.

[![Support on Ko-fi](https://storage.ko-fi.com/cdn/kofi2.png?v=3)](https://ko-fi.com/mikarregui)

## License

[MIT](LICENSE) © mikarregui

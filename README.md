# Skyline Rush — Simulator Tycoon

A Roblox Simulator + Tycoon prototype built with Luau and Rojo.

## Core loop

1. Explore the floating island and collect Energy Crystals.
2. Sell crystals at the Energy Exchange to earn Coins.
3. Upgrade movement speed and increase collection efficiency.
4. Claim a personal plot and buy an Energy Generator.
5. Generators produce passive Coins every 5 seconds; reinvest earnings into higher generator levels.

## Features

- Server-authoritative crystal collection, selling, upgrades and generator purchases.
- Four personal tycoon plots per server.
- Generator levels with escalating costs and passive income.
- DataStore persistence with retries, numeric validation, periodic saves and shutdown saves.
- Client HUD displaying resources, upgrades and passive income.
- Procedurally generated Roblox-native environment; no external mesh dependency.

## Repository layout

```text
src/
  client/HUD.client.lua
  server/Main.server.lua
  server/Services/
    GameService.lua
    PlayerDataService.lua
    WorldService.lua
  shared/Config.lua
default.project.json
aftman.toml
```

## Build

The GitHub Actions workflow builds `SkylineRush.rbxlx` using Rojo and uploads it as the `SkylineRush-place` artifact.

For local development, install Rojo 7.5.1 and run:

```bash
rojo build -o SkylineRush.rbxlx
```

Open the resulting place file in Roblox Studio.

## DataStore testing

DataStore requires a published test experience and API services enabled for that private test experience. Validate persistence in a controlled test before any public release.

## Known limitations

This is a prototype, not a production release. The current tycoon implementation has one generator upgrade chain per plot; additional building types, plot expansion, onboarding, balancing, mobile layout validation, multiplayer playtesting and analytics are future work. Runtime behavior has not been executed in Roblox Studio in this delivery.

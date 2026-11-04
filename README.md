# Skyline Rush ✦

**A source-first Roblox Simulator + Tycoon portfolio prototype.** Built with Luau and Rojo; can be reviewed or built from GitHub without the author installing Roblox Studio.

> **Status:** Source-complete prototype with automated build. Runtime gameplay, persistence and multiplayer tests require Roblox Studio and are not yet certified.

## Gameplay

Collect luminous crystals on a floating island, sell them for coins, improve speed and bag size, claim your own tycoon plot, upgrade an energy generator for recurring income, and unlock two more resource zones. Compete via `leaderstats` and persist progress between sessions when DataStore is available.

### Features

- Three zones with a rising crystal sell value (5 / 12 / 26 coins).
- Separate speed, bag capacity, generator and zone progression.
- Four personal plots, server-authoritative generator purchases and passive income.
- Player HUD with wallet, bag progress, level costs, income and notifications.
- Leaderboard: coins and lifetime crystals collected.
- Procedures, trees, energy pylons, lights and tycoon machinery generated using **original Roblox-native primitives** (no external assets or paid dependencies).
- DataStore sanitization, load retries, periodic saves, safe Studio guest mode and server-side interaction checks.
- GitHub Actions: repository invariant tests, StyLua parsing/formatting, Rojo place generation and XML validation.

## How to open the game

### From GitHub Actions (no Rojo needed)

1. Go to **Actions → Validate and Build SkylineRush → latest successful run**.
2. Download `SkylineRush-place` from **Artifacts** and unzip it.
3. Open `SkylineRush.rbxlx` in Roblox Studio and press **Play**.
4. If DataStore access isn't enabled, a `STUDIO DEMO MODE` notice appears; gameplay works but **changes are not saved**.

### From source

Install [Rojo 7.5.1](https://rojo.space/), then:

```bash
rojo build -o SkylineRush.rbxlx
```

Open the file in Roblox Studio.

### Persistence

Roblox DataStore requires a **published private test experience** with Studio API services enabled. Do not enable Studio API access against production data. The save key remains `SkylineRush_PlayerData_v2` for backward compatibility with earlier prototypes. If a legacy save includes the old `Capacity` field it is mapped into the new `CapacityLevel`.

See [Roblox DataStore documentation](https://create.roblox.com/docs/cloud-services/data-stores).

## Source architecture

```text
src/
  shared/Config.lua           Tuneable progression and world settings
  shared/Economy.lua          Pure domain operations and save sanitation
  server/Main.server.lua     Bootstraps remotes and modules
  server/Services/
    PlayerDataService.lua      Persistence and Studio fallback
    GameService.lua            Server-authoritative progression
    WorldService.lua           Original procedural 3D level and prompts
  client/HUD.client.lua       Local UI / notifications
```

## Validation and limitations

`python -m unittest discover -s tests -v` runs offline repository / economy contract checks. CI additionally runs StyLua and Rojo, then checks that the build is valid Roblox XML. **A successful CI build does not mean Luau gameplay and DataStore are runtime-tested.** See [REPORT.md](REPORT.md) and [docs/TEST_PLAN.md](docs/TEST_PLAN.md).

## Authoring and AI disclosure

The code and documentation were produced with AI assistance and should be reviewed as a code portfolio prototype, not represented as a shipped Roblox game or a validated commercial title.

## Assets

All visible props are generated in code. Optional CC0 replacement art references are documented in [ASSET_SOURCES.md](ASSET_SOURCES.md).

# Skyline Rush v2 — implementation report

## Changes in v2

- Fixed player-data sanitization order: Capacity is validated before Crystals are clamped against it.
- Added finite-number and integer bounds validation for persisted values.
- Added `GeneratorLevel` to the persisted player schema.
- Added periodic player-data saves and bounded shutdown saving.
- Added four personal tycoon plots per server.
- Added ownership checks for generator purchases.
- Added generator upgrades with escalating costs and passive coin production.
- Extended the HUD with generator level, next cost and passive income.
- Updated project documentation.

## Automated checks

- JSON project configuration parses successfully.
- All configured Rojo source paths exist.
- Expected Luau modules and workflow files exist.
- ZIP packaging integrity is checked.
- GitHub Actions Rojo build should be rerun after uploading this version.

## Not verified

- Roblox Studio runtime execution.
- Actual DataStore persistence and API permissions.
- Multiplayer concurrency and plot allocation under load.
- Prompt behavior, character spawn positions and visual quality in-engine.
- Economy balance, retention, monetization or moderation acceptance.

## Important implementation note

Generator level is saved, but the current prototype should be extended to visually reconstruct the generator when a returning player claims a plot. The saved passive income value still works after rejoining, but the visible generator reconstruction is not yet implemented.

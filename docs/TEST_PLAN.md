# In-engine acceptance test plan

The CI checks cannot execute Roblox runtime services. A reviewer should validate the following in a private Studio test experience:

1. Start a local solo test: spawn on the main island, see the HUD. If DataStore is unavailable, a **Studio demo** warning must appear and gameplay must remain available.
2. Collect one cyan crystal: bag count and estimated bag value increase.
3. Attempt to collect while the bag is full: count must not exceed capacity.
4. Sell on the gold terminal: bag returns to zero and coins increase.
5. Upgrade Speed: coins decrease, speed level and WalkSpeed increase.
6. Upgrade Capacity: max carry amount increases.
7. Buy Generator at own base: generator appears and earns coins every 5 seconds.
8. Try another player's generator: must deny purchase.
9. Try to collect zone 2 before unlocking: no crystal is awarded.
10. Unlock zone 2, then collect its higher-value crystals.
11. Join with two test players; confirm different personal plots and leaderstats updates.
12. Publish a **separate private test** experience, enable Studio API access, make progress, leave and rejoin; validate Coins, upgrades and generator display restored.
13. Disconnect and rejoin during an active save; verify no unexpected reset. Note this prototype does not yet guarantee transactional multi-session safety.
14. Test keyboard/mouse and touch controls; assess HUD overlap on small screens.
15. Inspect Studio Output for Lua errors and verify all prompts are reachable.

No results from these runtime checks are claimed in this repository unless a reviewer documents them.

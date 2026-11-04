"""Offline integrity and economy-model contract checks.

These tests DO NOT run Luau or Roblox physics / DataStore. The source parser
in GitHub Actions (StyLua) and Rojo build are additional independent checks.
"""
from pathlib import Path
import json
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
CONFIG = (ROOT / "src/shared/Config.lua").read_text(encoding="utf-8")
ECONOMY = (ROOT / "src/shared/Economy.lua").read_text(encoding="utf-8")


def scalar(name):
    match = re.search(rf"^Config\.{name}\s*=\s*(\d+)", CONFIG, re.M)
    if not match:
        raise ValueError(f"Missing numeric Config.{name}")
    return int(match.group(1))


class RepositoryTests(unittest.TestCase):
    def test_rojo_paths(self):
        data = json.loads((ROOT / "default.project.json").read_text())
        expected = ("src/shared", "src/server", "src/client")
        for path in expected:
            self.assertTrue((ROOT / path).is_dir(), path)
        paths = []
        def traverse(node):
            if isinstance(node, dict):
                if "$path" in node:
                    paths.append(node["$path"])
                for v in node.values():
                    traverse(v)
        traverse(data)
        self.assertEqual(sorted(paths), sorted(expected))

    def test_critical_modules_exist(self):
        for path in [
            "src/server/Main.server.lua",
            "src/client/HUD.client.lua",
            "src/shared/Config.lua",
            "src/shared/Economy.lua",
            "src/server/Services/WorldService.lua",
            "src/server/Services/GameService.lua",
            "src/server/Services/PlayerDataService.lua",
        ]:
            self.assertTrue((ROOT / path).is_file(), path)
            self.assertGreater((ROOT / path).stat().st_size, 100)

    def test_economy_constants_are_consistent(self):
        base = scalar("BaseCapacity")
        per_level = scalar("CapacityPerLevel")
        max_level = scalar("MaxCapacityLevel")
        self.assertGreater(base, 0)
        self.assertGreater(per_level, 0)
        self.assertLessEqual(base + per_level * max_level, 500)
        for name in ("MaxSpeedLevel", "MaxGeneratorLevel", "MaxZoneLevel", "AutoSaveSeconds"):
            self.assertGreater(scalar(name), 0)

    def test_economy_rules_are_server_side(self):
        self.assertIn("function Economy.Normalize", ECONOMY)
        self.assertIn("data.CapacityLevel = validInteger", ECONOMY)
        self.assertIn("data.Crystals = validInteger", ECONOMY)
        self.assertLess(ECONOMY.index("data.CapacityLevel = validInteger"), ECONOMY.index("data.Crystals = validInteger"))
        server = (ROOT / "src/server/Services/GameService.lua").read_text()
        self.assertIn("isNear(player, crystalPart", server)
        self.assertIn("Economy.Purchase", server)
        self.assertIn("rateLimit", server)
        self.assertNotIn("OnClientEvent", server)

    def test_guest_mode_does_not_save(self):
        data = (ROOT / "src/server/Services/PlayerDataService.lua").read_text()
        self.assertIn("RunService:IsStudio()", data)
        self.assertIn("record.Guest", data)
        self.assertIn("player:Kick", data)

    def test_no_remote_client_authoritative_currency(self):
        client = (ROOT / "src/client/HUD.client.lua").read_text()
        self.assertNotIn("Coins.Value", client)
        self.assertNotIn("Economy.Purchase", client)

    def test_legacy_bag_value_migration(self):
        self.assertIn('saved.BagValue == nil', ECONOMY)
        self.assertIn('saved.CapacityLevel == nil', ECONOMY)
        self.assertIn('config.CrystalValuePerZone[1]', ECONOMY)

    def test_ci_workflow_exists(self):
        workflow = ROOT / ".github/workflows/rojo-build.yml"
        self.assertTrue(workflow.exists())
        content = workflow.read_text()
        self.assertIn("rojo build", content)
        self.assertIn("unittest discover", content)
        self.assertIn("stylua-action", content)


if __name__ == "__main__":
    unittest.main()

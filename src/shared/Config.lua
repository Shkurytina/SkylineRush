local Config = {}

Config.DataStoreName = "SkylineRush_PlayerData_v1"
Config.StartingData = { Coins = 0, Crystals = 0, Capacity = 10, SpeedLevel = 0 }
Config.CrystalValue = 5
Config.CrystalRespawnSeconds = 5
Config.InitialCrystalCount = 32
Config.UpgradeBaseCost = 50
Config.UpgradeCostMultiplier = 1.6
Config.SpeedPerLevel = 2
Config.BaseWalkSpeed = 16
Config.MaxSpeedLevel = 10
Config.Map = { IslandSize = Vector3.new(190, 10, 190), CrystalAreaRadius = 66, CrystalSpawnHeight = 7 }

return Config

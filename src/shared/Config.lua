local Config = {}

-- Preserve the existing v2 save key: do not reset existing player progress.
Config.SaveKey = "SkylineRush_PlayerData_v2"
Config.AllowStudioGuestMode = true -- Studio-only if live DataStore is inaccessible.
Config.Defaults = {
    Coins = 0,
    Crystals = 0,
    CapacityLevel = 0,
    SpeedLevel = 0,
    GeneratorLevel = 0,
    ZoneLevel = 0,
    TotalCollected = 0,
    BagValue = 0,
}

Config.BaseCapacity = 10
Config.CapacityPerLevel = 5
Config.MaxCapacityLevel = 12
Config.MaxSpeedLevel = 10
Config.MaxGeneratorLevel = 10
Config.MaxZoneLevel = 2
Config.BaseWalkSpeed = 16
Config.SpeedPerLevel = 2
Config.CrystalRespawnSeconds = 7
Config.IncomeInterval = 5
Config.AutoSaveSeconds = 90
Config.CrystalCountPerZone = {28, 18, 14}
Config.CrystalValuePerZone = {5, 12, 26}
Config.GeneratorIncomePerLevel = 8
Config.MaxCoins = 2000000000
Config.MaxTotalCollected = 2000000000

Config.Costs = {
    Speed = {base = 50, factor = 1.55},
    Capacity = {base = 60, factor = 1.65},
    Generator = {base = 100, factor = 1.8},
    Zone = {300, 1500},
}

Config.ZoneNames = {"SKY MEADOW", "AZURE RIDGE", "NEON SUMMIT"}
Config.World = {
    GroundY = 5,
    MainSize = Vector3.new(250, 12, 240),
    ZoneCenters = {Vector3.new(0, 0, -23), Vector3.new(-85, 0, -78), Vector3.new(85, 0, -78)},
    Spawn = Vector3.new(0, 12, 85),
}
return Config

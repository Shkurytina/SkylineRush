-- Pure deterministic gameplay math: no Roblox services, remotes, or DataStore.
local Economy = {}

local function validInteger(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.clamp(math.floor(value), minimum, maximum)
end

function Economy.Capacity(data, config)
    return config.BaseCapacity + data.CapacityLevel * config.CapacityPerLevel
end

function Economy.Cost(kind, level, config)
    if kind == "Zone" then
        return config.Costs.Zone[level + 1]
    end
    local item = config.Costs[kind]
    if not item then return nil end
    return math.floor(item.base * item.factor ^ level)
end

function Economy.Normalize(saved, config)
    local data = table.clone(config.Defaults)
    if type(saved) == "table" then
        -- Support the v2 save schema without resetting coins/upgrades.
        for key in pairs(data) do
            if saved[key] ~= nil then data[key] = saved[key] end
        end
        if saved.CapacityLevel == nil and type(saved.Capacity) == "number" then
            data.CapacityLevel = math.floor((saved.Capacity - config.BaseCapacity) / config.CapacityPerLevel)
        end
    end
    data.CapacityLevel = validInteger(data.CapacityLevel, 0, 0, config.MaxCapacityLevel)
    data.SpeedLevel = validInteger(data.SpeedLevel, 0, 0, config.MaxSpeedLevel)
    data.GeneratorLevel = validInteger(data.GeneratorLevel, 0, 0, config.MaxGeneratorLevel)
    data.ZoneLevel = validInteger(data.ZoneLevel, 0, 0, config.MaxZoneLevel)
    data.Coins = validInteger(data.Coins, 0, 0, config.MaxCoins)
    data.Crystals = validInteger(data.Crystals, 0, 0, Economy.Capacity(data, config))
    data.TotalCollected = validInteger(data.TotalCollected, 0, 0, config.MaxTotalCollected)
    if type(saved) ~= "table" or saved.BagValue == nil then
        -- v2 stored only crystal count, so migrate the remaining bag at base value.
        data.BagValue = data.Crystals * config.CrystalValuePerZone[1]
    end
    data.BagValue = validInteger(data.BagValue, data.Crystals * config.CrystalValuePerZone[1], 0, data.Crystals * config.CrystalValuePerZone[#config.CrystalValuePerZone])
    return data
end

function Economy.Collect(data, zone, config)
    if zone < 1 or zone > data.ZoneLevel + 1 then return false, "zone_locked" end
    if data.Crystals >= Economy.Capacity(data, config) then return false, "bag_full" end
    data.Crystals += 1
    data.TotalCollected = math.min(data.TotalCollected + 1, config.MaxTotalCollected)
    -- All crystals share a bag slot. Higher zone resources sell for more using
    -- a weighted bag value persisted as `BagValue`.
    data.BagValue = math.min((data.BagValue or 0) + config.CrystalValuePerZone[zone], config.MaxCoins)
    return true
end

function Economy.Sell(data, config)
    if data.Crystals <= 0 then return false end
    local amount = data.BagValue or data.Crystals * config.CrystalValuePerZone[1]
    data.Coins = math.min(config.MaxCoins, data.Coins + amount)
    data.Crystals = 0
    data.BagValue = 0
    return true
end

function Economy.Purchase(data, kind, config)
    local key = kind .. "Level"
    local maxKey = "Max" .. kind .. "Level"
    if data[key] == nil or config[maxKey] == nil then return false, "unknown_upgrade" end
    if data[key] >= config[maxKey] then return false, "max_level" end
    local cost = Economy.Cost(kind, data[key], config)
    if not cost or data.Coins < cost then return false, "not_enough_coins" end
    data.Coins -= cost
    data[key] += 1
    return true
end

function Economy.GrantPassive(data, config)
    if data.GeneratorLevel <= 0 then return false end
    local reward = data.GeneratorLevel * config.GeneratorIncomePerLevel
    data.Coins = math.min(config.MaxCoins, data.Coins + reward)
    return true
end

return Economy

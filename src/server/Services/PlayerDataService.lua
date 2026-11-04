local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local PlayerDataService = {}
local cache = {}
local loaded = {}

local function defaults()
    local data = {}
    for key, value in pairs(Config.StartingData) do data[key] = value end
    return data
end

local function snapshot(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return result
end

function PlayerDataService:Get(player)
    if not loaded[player] then return nil end
    return cache[player]
end

function PlayerDataService:Load(player)
    local success, saved
    for attempt = 1, 3 do
        success, saved = pcall(function()
            return store:GetAsync("player_" .. player.UserId)
        end)
        if success then break end
        warn(string.format("[Data] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(saved)))
        task.wait(attempt * 2)
    end

    if not success then
        player:Kick("Your data could not be loaded. Please rejoin in a moment.")
        return nil
    end

    local data = defaults()
    if type(saved) == "table" then
        for key, defaultValue in pairs(Config.StartingData) do
            if type(saved[key]) == type(defaultValue) then data[key] = saved[key] end
        end
    end
    data.Coins = math.max(0, math.floor(data.Coins))
    data.Crystals = math.clamp(math.floor(data.Crystals), 0, data.Capacity)
    data.Capacity = math.clamp(math.floor(data.Capacity), 1, 500)
    data.SpeedLevel = math.clamp(math.floor(data.SpeedLevel), 0, Config.MaxSpeedLevel)
    cache[player] = data
    loaded[player] = true
    return data
end

function PlayerDataService:Save(player)
    local data = self:Get(player)
    if not data then return false end
    local savedSnapshot = snapshot(data)
    local success, err = pcall(function()
        store:UpdateAsync("player_" .. player.UserId, function()
            return savedSnapshot
        end)
    end)
    if not success then warn("[Data] Save failed for " .. player.Name .. ": " .. tostring(err)) end
    return success
end

function PlayerDataService:Remove(player)
    self:Save(player)
    cache[player] = nil
    loaded[player] = nil
end

function PlayerDataService:Start()
    Players.PlayerAdded:Connect(function(player) self:Load(player) end)
    Players.PlayerRemoving:Connect(function(player) self:Remove(player) end)
    for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() self:Load(player) end) end
    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do self:Save(player) end
    end)
end

return PlayerDataService

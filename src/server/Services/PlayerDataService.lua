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
    for key, value in pairs(Config.StartingData) do
        data[key] = value
    end
    return data
end

local function validInteger(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.clamp(math.floor(value), minimum, maximum)
end

local function sanitize(saved)
    local data = defaults()
    if type(saved) == "table" then
        for key, defaultValue in pairs(Config.StartingData) do
            if type(saved[key]) == type(defaultValue) then
                data[key] = saved[key]
            end
        end
    end

    -- Validate capacity before using it to clamp the crystal count.
    data.Capacity = validInteger(data.Capacity, 1, 500, Config.StartingData.Capacity)
    data.Coins = validInteger(data.Coins, 0, 2000000000, 0)
    data.Crystals = validInteger(data.Crystals, 0, data.Capacity, 0)
    data.SpeedLevel = validInteger(data.SpeedLevel, 0, Config.MaxSpeedLevel, 0)
    data.GeneratorLevel = validInteger(data.GeneratorLevel, 0, Config.Tycoon.MaxGeneratorLevel, 0)
    return data
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

    local data = sanitize(saved)
    cache[player] = data
    loaded[player] = true
    return data
end

function PlayerDataService:Save(player)
    local data = self:Get(player)
    if not data then return false end

    local snapshot = table.clone(data)
    local success, err = pcall(function()
        store:UpdateAsync("player_" .. player.UserId, function()
            return snapshot
        end)
    end)
    if not success then
        warn("[Data] Save failed for " .. player.Name .. ": " .. tostring(err))
    end
    return success
end

function PlayerDataService:Remove(player)
    self:Save(player)
    cache[player] = nil
    loaded[player] = nil
end

function PlayerDataService:Start()
    Players.PlayerAdded:Connect(function(player)
        self:Load(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self:Remove(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:Load(player) end)
    end

    -- Periodic saves reduce progress loss if a server closes unexpectedly.
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(function() self:Save(player) end)
            end
        end
    end)

    game:BindToClose(function()
        local pending = 0
        for _, player in ipairs(Players:GetPlayers()) do
            pending += 1
            task.spawn(function()
                self:Save(player)
                pending -= 1
            end)
        end
        local deadline = os.clock() + 25
        while pending > 0 and os.clock() < deadline do
            task.wait(0.1)
        end
    end)
end

return PlayerDataService

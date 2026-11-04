local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local store = DataStoreService:GetDataStore(Config.SaveKey)
local Service = {}
local records = {}

local function storeKey(player)
    return "player_" .. player.UserId
end

function Service:Get(player)
    local record = records[player]
    return record and record.Data or nil
end

function Service:IsGuest(player)
    local record = records[player]
    return record and record.Guest or false
end

function Service:Load(player)
    local ok, result = false, nil
    for attempt = 1, 3 do
        ok, result = pcall(function()
            return store:GetAsync(storeKey(player))
        end)
        if ok then break end
        warn("DataStore load attempt", attempt, "failed:", tostring(result))
        task.wait(attempt)
    end

    local guest = false
    if not ok then
        if RunService:IsStudio() and Config.AllowStudioGuestMode then
            guest = true
            result = nil
            warn("SkylineRush: Studio guest mode enabled; progress will NOT be saved.")
        else
            player:Kick("Progress could not be loaded. Please reconnect.")
            return nil
        end
    end
    local data = Economy.Normalize(result, Config)
    records[player] = {Data = data, Guest = guest, Saving = false}
    return data
end

function Service:Save(player)
    local record = records[player]
    if not record or record.Guest or record.Saving then return end
    record.Saving = true
    local snapshot = Economy.Normalize(record.Data, Config)
    local success, err = pcall(function()
        store:UpdateAsync(storeKey(player), function(previous)
            -- Persist a coherent snapshot; do not reset data on failed loads.
            -- For this MVP, concurrent same-user sessions are not supported.
            return snapshot
        end)
    end)
    record.Saving = false
    if not success then warn("Save failed:", player.Name, err) end
end

function Service:Start()
    Players.PlayerAdded:Connect(function(player)
        self:Load(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self:Save(player)
        records[player] = nil
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:Load(player) end)
    end
    task.spawn(function()
        while true do
            task.wait(Config.AutoSaveSeconds)
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
        while pending > 0 and os.clock() < deadline do task.wait(0.1) end
    end)
end

return Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)

local Service = {}
local ownedPlots = {}
local actionTimes = {}

local function isNear(player, target, maxDistance)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and humanoid.Health > 0 and root ~= nil
        and (root.Position - target.Position).Magnitude <= maxDistance
end

local function rateLimit(player, key, delaySeconds)
    local now = os.clock()
    actionTimes[player] = actionTimes[player] or {}
    local previous = actionTimes[player][key] or -math.huge
    if now - previous < delaySeconds then return false end
    actionTimes[player][key] = now
    return true
end

function Service:Notify(player, message)
    self.NotifyEvent:FireClient(player, message)
end

function Service:Sync(player)
    local data = self.Data:Get(player)
    if not data then return end
    local nextCosts = {}
    for _, name in ipairs({"Speed", "Capacity", "Generator", "Zone"}) do
        local level = data[name .. "Level"]
        nextCosts[name] = level >= Config["Max" .. name .. "Level"] and "MAX" or Economy.Cost(name, level, Config)
    end
    self.SyncEvent:FireClient(player, {
        Coins = data.Coins,
        Crystals = data.Crystals,
        BagValue = data.BagValue,
        Capacity = Economy.Capacity(data, Config),
        SpeedLevel = data.SpeedLevel,
        CapacityLevel = data.CapacityLevel,
        GeneratorLevel = data.GeneratorLevel,
        ZoneLevel = data.ZoneLevel,
        TotalCollected = data.TotalCollected,
        IncomePerTick = data.GeneratorLevel * Config.GeneratorIncomePerLevel,
        IncomeInterval = Config.IncomeInterval,
        NextCosts = nextCosts,
        IsGuest = self.Data:IsGuest(player),
    })
    local leaderboard = player:FindFirstChild("leaderstats")
    if leaderboard then
        leaderboard.Coins.Value = data.Coins
        leaderboard.Collected.Value = data.TotalCollected
    end
end

function Service:ApplySpeed(player)
    local data = self.Data:Get(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if data and humanoid then
        humanoid.WalkSpeed = Config.BaseWalkSpeed + data.SpeedLevel * Config.SpeedPerLevel
    end
end

function Service:Purchase(player, kind)
    local data = self.Data:Get(player)
    if not data or not rateLimit(player, kind, 0.35) then return end
    local success, reason = Economy.Purchase(data, kind, Config)
    if not success then
        if reason == "not_enough_coins" then self:Notify(player, "Not enough coins!") end
        if reason == "max_level" then self:Notify(player, "Already at maximum level") end
        return
    end
    if kind == "Speed" then self:ApplySpeed(player) end
    if kind == "Generator" then
        local plot = ownedPlots[player]
        if plot then self.World:RenderGenerator(plot, data.GeneratorLevel) end
    end
    if kind == "Zone" then
        self:Notify(player, "NEW ZONE UNLOCKED: " .. Config.ZoneNames[data.ZoneLevel + 1])
    end
    self:Sync(player)
end

function Service:AssignPlot(player)
    if ownedPlots[player] then return end
    for _, plot in ipairs(self.World.Plots) do
        if plot.OwnerId == nil then
            plot.OwnerId = player.UserId
            plot.Label.Text = player.DisplayName .. "'S TYCOON"
            ownedPlots[player] = plot
            local data = self.Data:Get(player)
            if data then self.World:RenderGenerator(plot, data.GeneratorLevel) end
            return
        end
    end
    self:Notify(player, "All tycoon plots are occupied on this server")
end

function Service:SetupPlayer(player)
    task.spawn(function()
        while player.Parent and not self.Data:Get(player) do task.wait(0.1) end
        if not player.Parent then return end
        local stats = Instance.new("Folder")
        stats.Name = "leaderstats"
        stats.Parent = player
        for _, name in ipairs({"Coins", "Collected"}) do
            local value = Instance.new("IntValue")
            value.Name = name
            value.Parent = stats
        end
        self:AssignPlot(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.2)
            self:ApplySpeed(player)
        end)
        self:ApplySpeed(player)
        self:Sync(player)
        if self.Data:IsGuest(player) then
            self:Notify(player, "STUDIO DEMO MODE — progress does not save")
        end
    end)
end

function Service:Start(dataService, worldService, syncEvent, notifyEvent)
    self.Data = dataService
    self.World = worldService
    self.SyncEvent = syncEvent
    self.NotifyEvent = notifyEvent
    local world = worldService:Create()

    local prompts = worldService.Prompts
    prompts.Sell.Triggered:Connect(function(player)
        if not isNear(player, prompts.Sell.Parent, 16) or not rateLimit(player, "Sell", 0.35) then return end
        local data = dataService:Get(player)
        if data and Economy.Sell(data, Config) then
            self:Sync(player)
            self:Notify(player, "Crystals sold!")
        end
    end)
    for _, kind in ipairs({"Speed", "Capacity", "Zone"}) do
        local p = prompts[kind]
        p.Triggered:Connect(function(player)
            if isNear(player, p.Parent, 16) then self:Purchase(player, kind) end
        end)
    end
    for _, plot in ipairs(worldService.Plots) do
        plot.Prompt.Triggered:Connect(function(player)
            if ownedPlots[player] == plot and plot.OwnerId == player.UserId
                and isNear(player, plot.Prompt.Parent, 16) then
                self:Purchase(player, "Generator")
            else
                self:Notify(player, "This is not your base")
            end
        end)
    end

    for zone, count in ipairs(Config.CrystalCountPerZone) do
        for _ = 1, count do
            worldService:SpawnCrystal(zone, function(player, crystalZone, crystalPart)
                if not isNear(player, crystalPart, 13) or not rateLimit(player, "Collect", 0.12) then return false end
                local data = dataService:Get(player)
                if not data then return false end
                local ok, reason = Economy.Collect(data, crystalZone, Config)
                if not ok then
                    if reason == "bag_full" then self:Notify(player, "Bag is full — sell crystals!") end
                    if reason == "zone_locked" then self:Notify(player, "Unlock this zone at the green terminal") end
                    return false
                end
                self:Sync(player)
                return true
            end)
        end
    end

    Players.PlayerAdded:Connect(function(player) self:SetupPlayer(player) end)
    Players.PlayerRemoving:Connect(function(player)
        local plot = ownedPlots[player]
        if plot then
            plot.OwnerId = nil
            plot.Label.Text = "AVAILABLE TYCOON"
            self.World:RenderGenerator(plot, 0)
        end
        ownedPlots[player] = nil
        actionTimes[player] = nil
    end)
    for _, player in ipairs(Players:GetPlayers()) do self:SetupPlayer(player) end

    task.spawn(function()
        while true do
            task.wait(Config.IncomeInterval)
            for player, plot in pairs(ownedPlots) do
                local data = self.Data:Get(player)
                if player.Parent and plot.OwnerId == player.UserId and data and Economy.GrantPassive(data, Config) then
                    self:Sync(player)
                end
            end
        end
    end)
end

return Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GameService = {}
local assignedPlots = {}

function GameService:Push(player)
    local data = self.DataService:Get(player)
    if not data then return end
    local speedCost = math.floor(Config.UpgradeBaseCost * (Config.UpgradeCostMultiplier ^ data.SpeedLevel))
    local generatorCost = math.floor(Config.Tycoon.GeneratorBaseCost * (Config.Tycoon.GeneratorCostMultiplier ^ data.GeneratorLevel))
    self.UpdateEvent:FireClient(player, {
        Coins = data.Coins,
        Crystals = data.Crystals,
        Capacity = data.Capacity,
        SpeedLevel = data.SpeedLevel,
        NextUpgradeCost = speedCost,
        GeneratorLevel = data.GeneratorLevel,
        NextGeneratorCost = generatorCost,
        GeneratorIncome = data.GeneratorLevel * Config.Tycoon.IncomePerLevel,
    })
end

function GameService:ApplyCharacterStats(player)
    local data = self.DataService:Get(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if data and humanoid then
        humanoid.WalkSpeed = Config.BaseWalkSpeed + data.SpeedLevel * Config.SpeedPerLevel
    end
end

function GameService:Collect(player)
    local data = self.DataService:Get(player)
    if not data or data.Crystals >= data.Capacity then return end
    data.Crystals += 1
    self:Push(player)
end

function GameService:Sell(player)
    local data = self.DataService:Get(player)
    if not data or data.Crystals <= 0 then return end
    data.Coins += data.Crystals * Config.CrystalValue
    data.Crystals = 0
    self:Push(player)
end

function GameService:Upgrade(player)
    local data = self.DataService:Get(player)
    if not data or data.SpeedLevel >= Config.MaxSpeedLevel then return end
    local cost = math.floor(Config.UpgradeBaseCost * (Config.UpgradeCostMultiplier ^ data.SpeedLevel))
    if data.Coins < cost then return end
    data.Coins -= cost
    data.SpeedLevel += 1
    self:ApplyCharacterStats(player)
    self:Push(player)
end

function GameService:RenderGenerator(plot, level)
    if plot.Generator then
        plot.Generator:Destroy()
        plot.Generator = nil
    end
    if level <= 0 then return end

    local generator = Instance.new("Part")
    generator.Name = "EnergyGenerator_Level" .. level
    generator.Size = Vector3.new(9, 7 + level, 9)
    generator.Position = plot.Origin + Vector3.new(0, 5 + level / 2, 0)
    generator.Anchored = true
    generator.Material = Enum.Material.Neon
    generator.Color = Color3.fromRGB(50, 210, 255)
    generator.Parent = plot.Model

    local light = Instance.new("PointLight")
    light.Color = generator.Color
    light.Range = 18
    light.Brightness = 2
    light.Parent = generator
    plot.Generator = generator
end

function GameService:ClaimPlot(player)
    if assignedPlots[player] then return assignedPlots[player] end
    for _, plot in ipairs(self.WorldService.Plots) do
        if not plot.OwnerUserId then
            plot.OwnerUserId = player.UserId
            plot.OwnerLabel.Text = player.DisplayName .. "'s BASE"
            assignedPlots[player] = plot
            local data = self.DataService:Get(player)
            if data then
                self:RenderGenerator(plot, data.GeneratorLevel)
            end
            return plot
        end
    end
    return nil
end

function GameService:BuyGenerator(player)
    local data = self.DataService:Get(player)
    local plot = assignedPlots[player]
    if not data or not plot or plot.OwnerUserId ~= player.UserId then return end
    if data.GeneratorLevel >= Config.Tycoon.MaxGeneratorLevel then return end

    local cost = math.floor(Config.Tycoon.GeneratorBaseCost * (Config.Tycoon.GeneratorCostMultiplier ^ data.GeneratorLevel))
    if data.Coins < cost then return end

    data.Coins -= cost
    data.GeneratorLevel += 1

    self:RenderGenerator(plot, data.GeneratorLevel)
    self:Push(player)
end

function GameService:SetupPlayer(player)
    task.spawn(function()
        while player.Parent and not self.DataService:Get(player) do
            task.wait(0.1)
        end
        if not player.Parent then return end
        self:ClaimPlot(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.25)
            self:ApplyCharacterStats(player)
        end)
        self:ApplyCharacterStats(player)
        self:Push(player)
    end)
end

function GameService:ReleasePlayer(player)
    local plot = assignedPlots[player]
    if plot then
        plot.OwnerUserId = nil
        plot.OwnerLabel.Text = "UNCLAIMED PLOT"
        if plot.Generator then
            plot.Generator:Destroy()
            plot.Generator = nil
        end
    end
    assignedPlots[player] = nil
end

function GameService:Start(dataService, updateEvent, worldService)
    self.DataService = dataService
    self.UpdateEvent = updateEvent
    self.WorldService = worldService

    worldService:Create()
    local world = workspace:WaitForChild("SkylineWorld")
    world.SellStation.ProximityPrompt.Triggered:Connect(function(player) self:Sell(player) end)
    world.UpgradePad.ProximityPrompt.Triggered:Connect(function(player) self:Upgrade(player) end)

    for _, plot in ipairs(worldService.Plots) do
        plot.Prompt.Triggered:Connect(function(player)
            if plot.OwnerUserId == player.UserId then
                self:BuyGenerator(player)
            end
        end)
    end

    for _ = 1, Config.InitialCrystalCount do
        worldService:SpawnCrystal(function(player) self:Collect(player) end)
    end

    Players.PlayerAdded:Connect(function(player) self:SetupPlayer(player) end)
    Players.PlayerRemoving:Connect(function(player) self:ReleasePlayer(player) end)
    for _, player in ipairs(Players:GetPlayers()) do self:SetupPlayer(player) end

    task.spawn(function()
        while true do
            task.wait(Config.Tycoon.IncomeInterval)
            for player, plot in pairs(assignedPlots) do
                local data = self.DataService:Get(player)
                if player.Parent and data and plot.OwnerUserId == player.UserId and data.GeneratorLevel > 0 then
                    data.Coins += data.GeneratorLevel * Config.Tycoon.IncomePerLevel
                    self:Push(player)
                end
            end
        end
    end)
end

return GameService

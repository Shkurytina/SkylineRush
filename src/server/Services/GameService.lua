local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameService = {}

function GameService:Push(player)
    local data = self.DataService:Get(player)
    if not data then return end
    self.UpdateEvent:FireClient(player, {
        Coins = data.Coins, Crystals = data.Crystals, Capacity = data.Capacity, SpeedLevel = data.SpeedLevel,
        NextUpgradeCost = math.floor(Config.UpgradeBaseCost * (Config.UpgradeCostMultiplier ^ data.SpeedLevel)),
    })
end

function GameService:ApplyCharacterStats(player)
    local data = self.DataService:Get(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if data and humanoid then humanoid.WalkSpeed = Config.BaseWalkSpeed + data.SpeedLevel * Config.SpeedPerLevel end
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
    data.Coins -= cost; data.SpeedLevel += 1
    self:ApplyCharacterStats(player); self:Push(player)
end

function GameService:SetupPlayer(player)
    task.spawn(function()
        while player.Parent and not self.DataService:Get(player) do task.wait(0.1) end
        if not player.Parent then return end
        player.CharacterAdded:Connect(function()
            task.wait(0.25); self:ApplyCharacterStats(player)
        end)
        self:ApplyCharacterStats(player); self:Push(player)
    end)
end

function GameService:Start(dataService, updateEvent, worldService)
    self.DataService = dataService; self.UpdateEvent = updateEvent
    local world = worldService:Create()
    world.SellStation.ProximityPrompt.Triggered:Connect(function(player) self:Sell(player) end)
    world.UpgradePad.ProximityPrompt.Triggered:Connect(function(player) self:Upgrade(player) end)
    for _ = 1, Config.InitialCrystalCount do
        worldService:SpawnCrystal(function(player) self:Collect(player) end)
    end
    Players.PlayerAdded:Connect(function(player) self:SetupPlayer(player) end)
    for _, player in ipairs(Players:GetPlayers()) do self:SetupPlayer(player) end
end

return GameService

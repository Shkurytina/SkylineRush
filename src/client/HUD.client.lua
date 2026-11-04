local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local updateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "SkylineHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "StatsPanel"
panel.Size = UDim2.fromOffset(310, 220)
panel.Position = UDim2.fromOffset(18, 18)
panel.BackgroundColor3 = Color3.fromRGB(17, 28, 45)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 190, 255)
stroke.Transparency = 0.35
stroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function makeLabel(name, order, height)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.LayoutOrder = order
    item.Size = UDim2.new(1, -12, 0, height or 24)
    item.BackgroundTransparency = 1
    item.TextColor3 = Color3.fromRGB(235, 245, 255)
    item.Font = Enum.Font.GothamMedium
    item.TextSize = 15
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = panel
    return item
end

local title = makeLabel("Title", 1, 30)
title.Text = "SKYLINE RUSH"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(85, 220, 255)

local coins = makeLabel("Coins", 2)
local crystals = makeLabel("Crystals", 3)
local speed = makeLabel("Speed", 4)
local generator = makeLabel("Generator", 5)
local income = makeLabel("Income", 6)

updateEvent.OnClientEvent:Connect(function(data)
    coins.Text = string.format("Coins: %d", data.Coins)
    crystals.Text = string.format("Crystals: %d / %d", data.Crystals, data.Capacity)
    speed.Text = string.format("Speed level: %d | Next: %d coins", data.SpeedLevel, data.NextUpgradeCost)
    generator.Text = string.format("Generator level: %d | Next: %d coins", data.GeneratorLevel, data.NextGeneratorCost)
    income.Text = string.format("Passive income: %d / %ds", data.GeneratorIncome, 5)
end)

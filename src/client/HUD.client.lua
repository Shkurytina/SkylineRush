local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local updateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "SkylineHUD"; gui.ResetOnSpawn = false; gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "StatsPanel"; panel.Size = UDim2.fromOffset(290, 145); panel.Position = UDim2.fromOffset(18, 18)
panel.BackgroundColor3 = Color3.fromRGB(17, 28, 45); panel.BackgroundTransparency = 0.08; panel.BorderSizePixel = 0; panel.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = panel
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(75, 190, 255); stroke.Transparency = 0.35; stroke.Parent = panel
local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 12); padding.PaddingLeft = UDim.new(0, 14); padding.Parent = panel
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = panel

local function label(name, order, height)
    local item = Instance.new("TextLabel"); item.Name = name; item.LayoutOrder = order
    item.Size = UDim2.new(1, -12, 0, height or 24); item.BackgroundTransparency = 1
    item.TextColor3 = Color3.fromRGB(235, 245, 255); item.Font = Enum.Font.GothamMedium; item.TextSize = 16
    item.TextXAlignment = Enum.TextXAlignment.Left; item.Parent = panel; return item
end
local title = label("Title", 1, 28); title.Text = "SKYLINE RUSH"; title.Font = Enum.Font.GothamBold; title.TextSize = 19; title.TextColor3 = Color3.fromRGB(85, 220, 255)
local coins = label("Coins", 2); local crystals = label("Crystals", 3); local speed = label("Speed", 4)

updateEvent.OnClientEvent:Connect(function(data)
    coins.Text = string.format("Coins: %d", data.Coins)
    crystals.Text = string.format("Crystals: %d / %d", data.Crystals, data.Capacity)
    speed.Text = string.format("Speed level: %d  |  Next: %d coins", data.SpeedLevel, data.NextUpgradeCost)
end)

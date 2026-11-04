local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local syncEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerSync")
local notifyEvent = ReplicatedStorage.Remotes:WaitForChild("Notify")

local screen = Instance.new("ScreenGui")
screen.Name = "SkylineHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = player:WaitForChild("PlayerGui")

local function rounded(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = frame
end

local panel = Instance.new("Frame")
panel.Name = "Dashboard"
panel.Size = UDim2.fromOffset(332, 282)
panel.Position = UDim2.fromOffset(16, 16)
panel.BackgroundColor3 = Color3.fromRGB(18, 29, 52)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Parent = screen
rounded(panel, 16)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(56, 210, 235)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = panel
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function label(order, height, fontSize, color)
    local text = Instance.new("TextLabel")
    text.LayoutOrder = order
    text.Size = UDim2.new(1, 0, 0, height)
    text.BackgroundTransparency = 1
    text.Font = order == 1 and Enum.Font.GothamBlack or Enum.Font.GothamMedium
    text.TextSize = fontSize or 15
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextColor3 = color or Color3.fromRGB(231, 245, 255)
    text.Text = ""
    text.Parent = panel
    return text
end

local heading = label(1, 32, 23, Color3.fromRGB(59, 230, 248))
heading.Text = "✦ SKYLINE RUSH"
local coins = label(2, 25, 18, Color3.fromRGB(255, 214, 107))
local crystals = label(3, 23)
local progress = Instance.new("Frame")
progress.LayoutOrder = 4
progress.Size = UDim2.new(1, 0, 0, 10)
progress.BackgroundColor3 = Color3.fromRGB(52, 70, 94)
progress.BorderSizePixel = 0
progress.Parent = panel
rounded(progress, 5)
local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = Color3.fromRGB(47, 221, 221)
progressFill.BorderSizePixel = 0
progressFill.Parent = progress
rounded(progressFill, 5)
local speed = label(5, 22)
local capacity = label(6, 22)
local generator = label(7, 22)
local zone = label(8, 22)
local earnings = label(9, 22, 14, Color3.fromRGB(133, 226, 179))
local tip = label(10, 24, 12, Color3.fromRGB(164, 182, 211))
tip.Text = "Collect → Sell → Upgrade → Build → Explore"

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.new(0.7, 0, 0, 48)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.fromScale(0.5, 0.05)
toast.BackgroundColor3 = Color3.fromRGB(22, 37, 62)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextSize = 18
toast.TextScaled = false
toast.Font = Enum.Font.GothamBold
toast.Parent = screen
rounded(toast, 14)

local nonce = 0
notifyEvent.OnClientEvent:Connect(function(message)
    nonce += 1
    local current = nonce
    toast.Text = tostring(message)
    TweenService:Create(toast, TweenInfo.new(0.15), {BackgroundTransparency = 0.05, TextTransparency = 0}):Play()
    task.delay(2.6, function()
        if nonce ~= current then return end
        TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
    end)
end)

local function costText(value)
    return type(value) == "number" and ("$" .. tostring(value)) or tostring(value)
end

syncEvent.OnClientEvent:Connect(function(data)
    coins.Text = string.format("COINS   %d", data.Coins)
    crystals.Text = string.format("CRYSTALS  %d / %d  |  Bag value $%d", data.Crystals, data.Capacity, data.BagValue)
    TweenService:Create(progressFill, TweenInfo.new(0.18), {
        Size = UDim2.fromScale(math.clamp(data.Crystals / math.max(1, data.Capacity), 0, 1), 1),
    }):Play()
    speed.Text = string.format("⚡ Speed Lv.%d  •  %s", data.SpeedLevel, costText(data.NextCosts.Speed))
    capacity.Text = string.format("▣ Bag Lv.%d  •  %s", data.CapacityLevel, costText(data.NextCosts.Capacity))
    generator.Text = string.format("✦ Generator Lv.%d  •  %s", data.GeneratorLevel, costText(data.NextCosts.Generator))
    zone.Text = string.format("◈ Zone %d / 3  •  %s", data.ZoneLevel + 1, costText(data.NextCosts.Zone))
    earnings.Text = string.format("Passive income: +%d coins / %ds   •   Collected %d", data.IncomePerTick, data.IncomeInterval, data.TotalCollected)
    if data.IsGuest then tip.Text = "STUDIO DEMO: progress not saved" end
end)

-- Request a fresh snapshot after all client handlers have been attached.
ReplicatedStorage.Remotes:WaitForChild("RequestSync"):FireServer()

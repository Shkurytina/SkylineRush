local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WorldService = {}
WorldService.CrystalsFolder = nil
WorldService.Plots = {}

local function part(parent, name, size, position, color, material, shape)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Anchored = true
    object.Color = color
    object.Material = material or Enum.Material.SmoothPlastic
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    if shape then object.Shape = shape end
    object.Parent = parent
    return object
end

local function prompt(parent, action, object, hold)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action
    p.ObjectText = object
    p.HoldDuration = hold or 0
    p.MaxActivationDistance = 12
    p.RequiresLineOfSight = false
    p.Parent = parent
    return p
end

function WorldService:Create()
    local old = Workspace:FindFirstChild("SkylineWorld")
    if old then old:Destroy() end
    local world = Instance.new("Folder")
    world.Name = "SkylineWorld"
    world.Parent = Workspace

    part(world, "FloatingIsland", Config.Map.IslandSize, Vector3.new(0, 0, 0), Color3.fromRGB(57, 112, 91), Enum.Material.Grass)
    part(world, "IslandUnderside", Vector3.new(170, 22, 170), Vector3.new(0, -15, 0), Color3.fromRGB(54, 65, 93), Enum.Material.Slate)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 6, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Color = Color3.fromRGB(75, 190, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Parent = world

    for i = 1, 8 do
        local angle = (math.pi * 2 / 8) * i
        local x, z = math.cos(angle) * 88, math.sin(angle) * 88
        part(world, "CrystalPylon", Vector3.new(3, 13, 3), Vector3.new(x, 9, z), Color3.fromRGB(58, 190, 220), Enum.Material.Neon)
        local cap = part(world, "PylonCap", Vector3.new(5, 2, 5), Vector3.new(x, 16, z), Color3.fromRGB(120, 235, 255), Enum.Material.Neon, Enum.PartType.Ball)
        cap.Transparency = 0.15
    end

    local sell = part(world, "SellStation", Vector3.new(18, 2, 18), Vector3.new(-20, 7, 38), Color3.fromRGB(255, 184, 65), Enum.Material.Neon)
    prompt(sell, "Sell crystals", "Energy Exchange", 0.25)
    local upgrade = part(world, "UpgradePad", Vector3.new(18, 2, 18), Vector3.new(20, 7, 38), Color3.fromRGB(100, 145, 255), Enum.Material.Neon)
    prompt(upgrade, "Upgrade speed", "Upgrade Terminal", 0.25)

    local plotsFolder = Instance.new("Folder")
    plotsFolder.Name = "TycoonPlots"
    plotsFolder.Parent = world
    self.Plots = {}

    local offsets = {
        Vector3.new(-65, 6, -65),
        Vector3.new(65, 6, -65),
        Vector3.new(-65, 6, 65),
        Vector3.new(65, 6, 65),
    }

    for index = 1, Config.Tycoon.PlotCount do
        local model = Instance.new("Model")
        model.Name = "Plot" .. index
        model.Parent = plotsFolder
        local origin = offsets[index]
        local base = part(model, "PlotBase", Vector3.new(48, 2, 38), origin, Color3.fromRGB(37, 54, 78), Enum.Material.Metal)
        local sign = part(model, "PlotSign", Vector3.new(12, 5, 1), origin + Vector3.new(0, 5, -17), Color3.fromRGB(32, 120, 170), Enum.Material.Neon)
        local surface = part(model, "GeneratorPad", Vector3.new(12, 1, 12), origin + Vector3.new(0, 2, 0), Color3.fromRGB(55, 180, 210), Enum.Material.Neon)
        local buyPrompt = prompt(surface, "Buy generator", "Tycoon generator", 0.5)
        local label = Instance.new("BillboardGui")
        label.Name = "OwnerLabel"
        label.Size = UDim2.fromOffset(180, 42)
        label.StudsOffset = Vector3.new(0, 4, 0)
        label.AlwaysOnTop = true
        label.Parent = sign
        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Text = "UNCLAIMED PLOT"
        text.TextColor3 = Color3.new(1, 1, 1)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = label
        self.Plots[index] = {
            Model = model,
            Base = base,
            Prompt = buyPrompt,
            OwnerLabel = text,
            Origin = origin,
            Generator = nil,
            OwnerUserId = nil,
        }
    end

    local crystals = Instance.new("Folder")
    crystals.Name = "Crystals"
    crystals.Parent = world
    self.CrystalsFolder = crystals
    return world
end

function WorldService:SpawnCrystal(onCollected)
    if not self.CrystalsFolder then return end
    local radius = Config.Map.CrystalAreaRadius
    local angle = math.random() * math.pi * 2
    local distance = math.sqrt(math.random()) * radius
    local x, z = math.cos(angle) * distance, math.sin(angle) * distance
    local crystal = part(self.CrystalsFolder, "EnergyCrystal", Vector3.new(2.5, 3.5, 2.5), Vector3.new(x, Config.Map.CrystalSpawnHeight, z), Color3.fromRGB(65, 225, 255), Enum.Material.Neon, Enum.PartType.Ball)
    crystal.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = crystal.Color
    light.Range = 10
    light.Brightness = 1.5
    light.Parent = crystal
    local p = prompt(crystal, "Collect", "Energy Crystal", 0)
    local collected = false
    p.Triggered:Connect(function(player)
        if collected then return end
        collected = true
        p.Enabled = false
        crystal:Destroy()
        onCollected(player)
        task.delay(Config.CrystalRespawnSeconds, function()
            self:SpawnCrystal(onCollected)
        end)
    end)
end

return WorldService

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local World = {}
World.Plots = {}
World.CrystalFolder = nil
World.Prompts = {}
World.ZoneBarriers = {}

local COLORS = {
    dark = Color3.fromRGB(23, 37, 63),
    stone = Color3.fromRGB(47, 62, 94),
    cyan = Color3.fromRGB(45, 226, 240),
    gold = Color3.fromRGB(255, 198, 83),
    violet = Color3.fromRGB(163, 107, 246),
    green = Color3.fromRGB(60, 168, 127),
}

local function part(parent, name, size, position, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function sphere(parent, name, pos, size, color, material)
    return part(parent, name, Vector3.new(size, size, size), pos, color, material or Enum.Material.Neon, Enum.PartType.Ball)
end

local function billboard(parent, words, tint, y)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Size = UDim2.fromOffset(245, 65)
    gui.StudsOffsetWorldSpace = Vector3.new(0, y or 5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 90
    gui.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = COLORS.dark
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Text = words
    label.TextColor3 = tint
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = label
    return label
end

local function actionPrompt(parent, action, object)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action
    p.ObjectText = object
    p.HoldDuration = 0.25
    p.MaxActivationDistance = 12
    p.RequiresLineOfSight = false
    p.Parent = parent
    return p
end

local function decorateTree(folder, x, z, scale)
    local trunk = part(folder, "TreeTrunk", Vector3.new(2, 8, 2) * scale, Vector3.new(x, 11, z), Color3.fromRGB(96, 70, 72), Enum.Material.Wood)
    local crown = sphere(folder, "TreeCrown", Vector3.new(x, 18, z), 11 * scale, Color3.fromRGB(35, 153, 139), Enum.Material.Grass)
    trunk.CanCollide = false
    crown.CanCollide = false
end

function World:Create()
    local previous = Workspace:FindFirstChild("SkylineWorld")
    if previous then previous:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = "SkylineWorld"
    folder.Parent = Workspace
    self.Prompts = {}
    self.Plots = {}
    self.ZoneBarriers = {}

    Lighting.ClockTime = 14
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(80, 126, 165)
    Lighting.OutdoorAmbient = Color3.fromRGB(90, 140, 180)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Density = 0.22
    atmosphere.Haze = 1.2
    atmosphere.Color = Color3.fromRGB(175, 217, 255)
    atmosphere.Parent = Lighting

    -- Main island and two elevated zone gardens, with bridges and unique materials.
    part(folder, "FloatingMainIsland", Config.World.MainSize, Vector3.new(0, -1, 0), COLORS.stone, Enum.Material.Slate)
    part(folder, "GrassTop", Vector3.new(248, 2, 238), Vector3.new(0, 6, 0), COLORS.green, Enum.Material.Grass)
    for zone = 2, 3 do
        local center = Config.World.ZoneCenters[zone]
        local color = zone == 2 and COLORS.cyan or COLORS.violet
        part(folder, "ZoneIsland" .. zone, Vector3.new(65, 7, 57), Vector3.new(center.X, 10, center.Z), COLORS.stone, Enum.Material.Slate)
        part(folder, "ZoneSurface" .. zone, Vector3.new(63, 2, 55), Vector3.new(center.X, 14, center.Z), color, Enum.Material.SmoothPlastic)
    end
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn"
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Size = Vector3.new(13, 1, 13)
    spawn.Position = Config.World.Spawn
    spawn.Material = Enum.Material.Neon
    spawn.Color = COLORS.cyan
    spawn.Parent = folder
    billboard(spawn, "SKYLINE RUSH\nCOLLECT • BUILD • EXPLORE", Color3.new(1, 1, 1), 9)

    local plaza = part(folder, "Plaza", Vector3.new(86, 1, 38), Vector3.new(0, 8, 51), COLORS.dark, Enum.Material.Metal)
    local labels = {
        {"Sell", -29, COLORS.gold, "SELL CRYSTALS"},
        {"Speed", -10, COLORS.cyan, "UPGRADE SPEED"},
        {"Capacity", 10, COLORS.violet, "BAG CAPACITY"},
        {"Zone", 29, COLORS.green, "UNLOCK ZONE"},
    }
    for _, v in ipairs(labels) do
        local pad = part(folder, v[1] .. "Pad", Vector3.new(16, 2, 14), Vector3.new(v[2], 9, 51), v[3], Enum.Material.Neon)
        self.Prompts[v[1]] = actionPrompt(pad, v[4], v[1] .. " terminal")
        billboard(pad, v[4], Color3.new(1, 1, 1), 6)
    end

    for n = 1, 11 do
        local x = -105 + (n % 6) * 42
        local z = -1 + math.floor(n / 6) * 24
        decorateTree(folder, x, z, (n % 3 == 0) and 0.8 or 1)
    end

    for i = 1, 4 do
        local positions = {
            Vector3.new(-82, 8, 25), Vector3.new(82, 8, 25),
            Vector3.new(-82, 8, 91), Vector3.new(82, 8, 91),
        }
        local origin = positions[i]
        local model = Instance.new("Model")
        model.Name = "TycoonPlot" .. i
        model.Parent = folder
        part(model, "Foundation", Vector3.new(46, 2, 40), origin, COLORS.dark, Enum.Material.Metal)
        local terminal = part(model, "GeneratorPurchase", Vector3.new(10, 2, 10), origin + Vector3.new(-11, 2, 7), COLORS.gold, Enum.Material.Neon)
        local generatorSpot = part(model, "GeneratorPlatform", Vector3.new(13, 1, 13), origin + Vector3.new(9, 2, -4), COLORS.cyan, Enum.Material.Metal)
        local nameLabel = billboard(terminal, "AVAILABLE TYCOON", Color3.new(1, 1, 1), 8)
        local purchase = actionPrompt(terminal, "BUY GENERATOR", "Private Tycoon")
        self.Plots[i] = {Model = model, Origin = origin, Prompt = purchase, Label = nameLabel, OwnerId = nil, Generator = nil, Platform = generatorSpot}
    end

    local crystals = Instance.new("Folder")
    crystals.Name = "Crystals"
    crystals.Parent = folder
    self.CrystalFolder = crystals
    return folder
end

function World:RenderGenerator(plot, level)
    if plot.Generator then plot.Generator:Destroy() end
    plot.Generator = nil
    if level <= 0 then return end
    local model = Instance.new("Model")
    model.Name = "EnergyGenerator_Level" .. level
    model.Parent = plot.Model
    local center = plot.Origin + Vector3.new(9, 5, -4)
    part(model, "GeneratorBody", Vector3.new(9, 6 + level, 9), center + Vector3.new(0, level / 2, 0), COLORS.dark, Enum.Material.Metal)
    for i = 1, 3 do
        local ring = part(model, "PowerCoil", Vector3.new(10, 0.7, 10), center + Vector3.new(0, i * 2, 0), COLORS.cyan, Enum.Material.Neon)
        ring.CanCollide = false
    end
    local core = sphere(model, "PowerCore", center + Vector3.new(0, 9 + level / 2, 0), 5, COLORS.cyan)
    core.CanCollide = false
    local light = Instance.new("PointLight")
    light.Range = 24
    light.Brightness = 3
    light.Color = COLORS.cyan
    light.Parent = core
    billboard(core, "GENERATOR LV. " .. level, COLORS.gold, 5)
    plot.Generator = model
end

function World:SpawnCrystal(zoneIndex, onTriggered)
    local zoneCenter = Config.World.ZoneCenters[zoneIndex]
    local halfWidth = zoneIndex == 1 and 62 or 23
    local x = zoneCenter.X + math.random(-halfWidth, halfWidth)
    local z = zoneCenter.Z + math.random(-20, 20)
    local altitude = zoneIndex == 1 and 9.2 or 17.2
    local tint = ({COLORS.cyan, COLORS.gold, COLORS.violet})[zoneIndex]
    local crystal = sphere(self.CrystalFolder, "Crystal_Z" .. zoneIndex, Vector3.new(x, altitude, z), 3.4, tint)
    crystal.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = tint
    light.Brightness = 1.6
    light.Range = 11
    light.Parent = crystal
    local prompt = actionPrompt(crystal, "COLLECT +" .. Config.CrystalValuePerZone[zoneIndex], Config.ZoneNames[zoneIndex])
    prompt.HoldDuration = 0
    local busy = false
    prompt.Triggered:Connect(function(player)
        if busy then return end
        local accepted = onTriggered(player, zoneIndex, crystal)
        if accepted then
            busy = true
            crystal:Destroy()
            task.delay(Config.CrystalRespawnSeconds, function()
                if self.CrystalFolder and self.CrystalFolder.Parent then
                    self:SpawnCrystal(zoneIndex, onTriggered)
                end
            end)
        end
    end)
end

return World

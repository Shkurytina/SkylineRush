local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldService = {}
WorldService.CrystalsFolder = nil

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
    part(world, "IslandUnderside", Vector3.new(150, 22, 150), Vector3.new(0, -15, 0), Color3.fromRGB(54, 65, 93), Enum.Material.Slate)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn"; spawn.Size = Vector3.new(12, 1, 12); spawn.Position = Vector3.new(0, 6, 0)
    spawn.Anchored = true; spawn.Neutral = true; spawn.Color = Color3.fromRGB(75, 190, 255); spawn.Material = Enum.Material.Neon; spawn.Parent = world

    -- Decorative low-poly crystal pylons and floating rock clusters. All geometry is generated from native Parts.
    for i = 1, 8 do
        local angle = (math.pi * 2 / 8) * i
        local x, z = math.cos(angle) * 72, math.sin(angle) * 72
        part(world, "CrystalPylon", Vector3.new(3, 13, 3), Vector3.new(x, 9, z), Color3.fromRGB(58, 190, 220), Enum.Material.Neon)
        local cap = part(world, "PylonCap", Vector3.new(5, 2, 5), Vector3.new(x, 16, z), Color3.fromRGB(120, 235, 255), Enum.Material.Neon, Enum.PartType.Ball)
        cap.Transparency = 0.15
    end
    for i = 1, 12 do
        local angle = (math.pi * 2 / 12) * i
        local x, z = math.cos(angle) * 90, math.sin(angle) * 90
        local cloud = part(world, "SkyCloud", Vector3.new(13, 5, 10), Vector3.new(x, 27 + (i % 3) * 3, z), Color3.fromRGB(190, 220, 238), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        cloud.Transparency = 0.2
    end

    local sell = part(world, "SellStation", Vector3.new(18, 2, 18), Vector3.new(-20, 7, 38), Color3.fromRGB(255, 184, 65), Enum.Material.Neon)
    prompt(sell, "Sell crystals", "Energy Exchange", 0.25)
    local upgrade = part(world, "UpgradePad", Vector3.new(18, 2, 18), Vector3.new(20, 7, 38), Color3.fromRGB(100, 145, 255), Enum.Material.Neon)
    prompt(upgrade, "Upgrade speed", "Upgrade Terminal", 0.25)

    local crystals = Instance.new("Folder")
    crystals.Name = "Crystals"; crystals.Parent = world
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
    local light = Instance.new("PointLight"); light.Color = crystal.Color; light.Range = 10; light.Brightness = 1.5; light.Parent = crystal
    local p = prompt(crystal, "Collect", "Energy Crystal", 0)
    local collected = false
    p.Triggered:Connect(function(player)
        if collected then return end
        collected = true; p.Enabled = false; crystal:Destroy()
        onCollected(player)
        task.delay(Config.CrystalRespawnSeconds, function() self:SpawnCrystal(onCollected) end)
    end)
end

return WorldService

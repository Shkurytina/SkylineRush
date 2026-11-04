local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local sync = Instance.new("RemoteEvent")
sync.Name = "PlayerSync"
sync.Parent = remotes

local notify = Instance.new("RemoteEvent")
notify.Name = "Notify"
notify.Parent = remotes

local request = Instance.new("RemoteEvent")
request.Name = "RequestSync"
request.Parent = remotes

local services = script.Parent.Services
local Data = require(services.PlayerDataService)
local World = require(services.WorldService)
local Game = require(services.GameService)

Data:Start()
Game:Start(Data, World, sync, notify)
local requestTimes = {}
request.OnServerEvent:Connect(function(player)
    local now = os.clock()
    if now - (requestTimes[player] or -math.huge) < 0.5 then return end
    requestTimes[player] = now
    Game:Sync(player)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    requestTimes[player] = nil
end)
print("[SkylineRush v3] initialized")

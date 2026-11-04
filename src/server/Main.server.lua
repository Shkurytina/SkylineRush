local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"; remotes.Parent = ReplicatedStorage
local updateEvent = remotes:FindFirstChild("PlayerUpdate") or Instance.new("RemoteEvent")
updateEvent.Name = "PlayerUpdate"; updateEvent.Parent = remotes

local services = script.Parent:WaitForChild("Services")
local PlayerDataService = require(services:WaitForChild("PlayerDataService"))
local WorldService = require(services:WaitForChild("WorldService"))
local GameService = require(services:WaitForChild("GameService"))

PlayerDataService:Start()
GameService:Start(PlayerDataService, updateEvent, WorldService)
print("[SkylineRush] Server initialized")

--!strict
-- Central registry of RemoteEvents / RemoteFunctions.
-- Server calls Remotes.Init() once; clients just call Remotes.Get(name).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "ForzaBloxRemotes"

local DEFINITIONS: { { name: string, class: string } } = {
	{ name = "ProfileUpdate", class = "RemoteEvent" },   -- S->C: credits / owned cars snapshot
	{ name = "Notify", class = "RemoteEvent" },          -- S->C: toast message (text, kind)
	{ name = "OpenDealership", class = "RemoteEvent" },  -- S->C: open dealership UI
	{ name = "OpenGarage", class = "RemoteEvent" },      -- S->C: open garage UI
	{ name = "SpawnCar", class = "RemoteEvent" },        -- C->S: spawn owned car (carId)
	{ name = "SetCarColor", class = "RemoteEvent" },     -- C->S: repaint active car (r, g, b)
	{ name = "RaceUpdate", class = "RemoteEvent" },      -- S->C: race lifecycle payloads
	{ name = "BuyCar", class = "RemoteFunction" },       -- C->S: purchase (carId) -> ok, message
}

local Remotes = {}

function Remotes.Init()
	assert(RunService:IsServer(), "Remotes.Init must be called from the server")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, def in DEFINITIONS do
		if not folder:FindFirstChild(def.name) then
			local remote = Instance.new(def.class)
			remote.Name = def.name
			remote.Parent = folder
		end
	end
end

function Remotes.Get(name: string): Instance
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name)
end

return Remotes

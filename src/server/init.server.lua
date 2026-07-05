--!strict
-- Cat Clicker server — Stage 1: the click mechanic.
-- Owns the Treats leaderstat and validates clicks (with a rate cap).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local clickEvent = Instance.new("RemoteEvent")
clickEvent.Name = "ClickTreat"
clickEvent.Parent = ReplicatedStorage

type ClickWindow = { windowStart: number, count: number }
local clickWindows: { [Player]: ClickWindow } = {}

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local treats = Instance.new("NumberValue")
	treats.Name = "Treats"
	treats.Value = 0
	treats.Parent = stats
	stats.Parent = player
	clickWindows[player] = { windowStart = os.clock(), count = 0 }
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	clickWindows[player] = nil
end)

clickEvent.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	local treats = stats and stats:FindFirstChild("Treats") :: NumberValue?
	local window = clickWindows[player]
	if not treats or not window then
		return
	end

	-- Rolling 1-second rate cap
	local now = os.clock()
	if now - window.windowStart >= 1 then
		window.windowStart = now
		window.count = 0
	end
	if window.count >= Config.MaxClicksPerSecond then
		return
	end
	window.count += 1

	local gained = Config.TreatsPerClick
	treats.Value += gained
	clickEvent:FireClient(player, gained)
end)

print("[CatClicker] Server ready — stage 1 (click mechanic)")

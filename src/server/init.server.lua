--!strict
-- Cat Clicker server — Stages 1-2: click mechanic + generator shop.
-- Owns the Treats leaderstat, validates clicks and purchases, and pays out
-- passive Treats-per-second from owned generators.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local clickEvent = Instance.new("RemoteEvent")
clickEvent.Name = "ClickTreat"
clickEvent.Parent = ReplicatedStorage

local buyEvent = Instance.new("RemoteEvent")
buyEvent.Name = "BuyGenerator"
buyEvent.Parent = ReplicatedStorage

local shopSync = Instance.new("RemoteEvent")
shopSync.Name = "ShopSync"
shopSync.Parent = ReplicatedStorage

local buyClickUpgrade = Instance.new("RemoteEvent")
buyClickUpgrade.Name = "BuyClickUpgrade"
buyClickUpgrade.Parent = ReplicatedStorage

type PlayerState = {
	windowStart: number,
	clickCount: number,
	counts: { [string]: number }, -- generatorId -> owned
	clickUpgrades: { [string]: boolean }, -- upgradeId -> owned
}
local states: { [Player]: PlayerState } = {}

local function getTreats(player: Player): NumberValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Treats") :: NumberValue?
end

local function syncShop(player: Player)
	local state = states[player]
	if state then
		shopSync:FireClient(player, {
			counts = state.counts,
			clickUpgrades = state.clickUpgrades,
		})
	end
end

-- ============================ PLAYERS ============================

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local treats = Instance.new("NumberValue")
	treats.Name = "Treats"
	treats.Value = 0
	treats.Parent = stats
	stats.Parent = player
	states[player] = { windowStart = os.clock(), clickCount = 0, counts = {}, clickUpgrades = {} }
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

-- ============================ CLICKS (Stage 1) ============================

clickEvent.OnServerEvent:Connect(function(player)
	local treats = getTreats(player)
	local state = states[player]
	if not treats or not state then
		return
	end

	local now = os.clock()
	if now - state.windowStart >= 1 then
		state.windowStart = now
		state.clickCount = 0
	end
	if state.clickCount >= Config.MaxClicksPerSecond then
		return
	end
	state.clickCount += 1

	local gained = Config.ClickAmount(state.clickUpgrades)
	treats.Value += gained
	clickEvent:FireClient(player, gained)
end)

-- ============================ CLICK UPGRADES (Stage 3) ============================

buyClickUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats or type(upgradeId) ~= "string" then
		return
	end
	local upgrade = Config.ClickUpgradesById[upgradeId]
	if not upgrade or state.clickUpgrades[upgradeId] then
		return
	end
	if treats.Value < upgrade.cost then
		return
	end

	treats.Value -= upgrade.cost
	state.clickUpgrades[upgradeId] = true
	syncShop(player)
end)

-- ============================ SHOP (Stage 2) ============================

buyEvent.OnServerEvent:Connect(function(player, generatorId)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats or type(generatorId) ~= "string" then
		return
	end
	local gen = Config.GeneratorsById[generatorId]
	if not gen then
		return
	end

	local owned = state.counts[generatorId] or 0
	local cost = Config.CostFor(gen, owned)
	if treats.Value < cost then
		return
	end

	treats.Value -= cost
	state.counts[generatorId] = owned + 1
	syncShop(player)
end)

shopSync.OnServerEvent:Connect(syncShop) -- client asks for its state on load

-- Passive income loop
task.spawn(function()
	local TICK = 0.25
	while true do
		task.wait(TICK)
		for player, state in states do
			local perSecond = 0
			for _, gen in Config.Generators do
				local owned = state.counts[gen.id]
				if owned and owned > 0 then
					perSecond += gen.rate * owned
				end
			end
			if perSecond > 0 then
				local treats = getTreats(player)
				if treats then
					treats.Value += perSecond * TICK
				end
			end
		end
	end
end)

print("[CatClicker] Server ready — stages 1-2 (clicks + shop)")

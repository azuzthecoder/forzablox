--!strict
-- Cat Clicker server — Stages 1-2: click mechanic + generator shop.
-- Owns the Treats leaderstat, validates clicks and purchases, and pays out
-- passive Treats-per-second from owned generators.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

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

local goldenOffer = Instance.new("RemoteEvent")
goldenOffer.Name = "GoldenCatOffer"
goldenOffer.Parent = ReplicatedStorage

local goldenClick = Instance.new("RemoteEvent")
goldenClick.Name = "GoldenCatClick"
goldenClick.Parent = ReplicatedStorage

local boostSync = Instance.new("RemoteEvent")
boostSync.Name = "BoostSync"
boostSync.Parent = ReplicatedStorage

local leaderboardSync = Instance.new("RemoteEvent")
leaderboardSync.Name = "LeaderboardSync"
leaderboardSync.Parent = ReplicatedStorage

local goldenRng = Random.new()

type PlayerState = {
	windowStart: number,
	clickCount: number,
	counts: { [string]: number }, -- generatorId -> owned
	clickUpgrades: { [string]: boolean }, -- upgradeId -> owned
	nextGoldenAt: number,
	goldenOfferExpires: number?,
	boostMult: number,
	boostEnds: number,
	totalEarned: number,
	clicks: number,
}

local function boostFor(state: PlayerState, now: number): number
	return now < state.boostEnds and state.boostMult or 1
end
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
	states[player] = {
		windowStart = os.clock(),
		clickCount = 0,
		counts = {},
		clickUpgrades = {},
		nextGoldenAt = os.clock()
			+ goldenRng:NextNumber(Config.GoldenCat.MinInterval, Config.GoldenCat.MaxInterval),
		goldenOfferExpires = nil,
		boostMult = 1,
		boostEnds = 0,
		totalEarned = 0,
		clicks = 0,
	}
	player:SetAttribute("TotalEarned", 0)
	player:SetAttribute("Clicks", 0)
	player:SetAttribute("PerSecond", 0)
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

	local gained = Config.ClickAmount(state.clickUpgrades) * boostFor(state, now)
	treats.Value += gained
	state.totalEarned += gained
	state.clicks += 1
	player:SetAttribute("TotalEarned", state.totalEarned)
	player:SetAttribute("Clicks", state.clicks)
	clickEvent:FireClient(player, gained)
end)

-- ============================ GOLDEN CAT (Stage 4) ============================

goldenClick.OnServerEvent:Connect(function(player)
	local state = states[player]
	if not state then
		return
	end
	local now = os.clock()
	if not state.goldenOfferExpires or now > state.goldenOfferExpires :: number then
		return -- no golden cat was live; ignore
	end
	state.goldenOfferExpires = nil

	local duration = goldenRng:NextNumber(Config.GoldenCat.MinDuration, Config.GoldenCat.MaxDuration)
	state.boostMult = Config.GoldenCat.Multiplier
	state.boostEnds = now + duration
	boostSync:FireClient(player, Config.GoldenCat.Multiplier, duration)
end)

-- Spawner: offers each player a golden cat on their own random schedule
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for player, state in states do
			if state.goldenOfferExpires and now > state.goldenOfferExpires :: number then
				state.goldenOfferExpires = nil
			end
			if not state.goldenOfferExpires and now >= state.nextGoldenAt then
				state.goldenOfferExpires = now + Config.GoldenCat.ClickWindow
				state.nextGoldenAt = now + Config.GoldenCat.MaxDuration
					+ goldenRng:NextNumber(Config.GoldenCat.MinInterval, Config.GoldenCat.MaxInterval)
				goldenOffer:FireClient(player, Config.GoldenCat.ClickWindow)
			end
		end
	end
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
			if player:GetAttribute("PerSecond") ~= perSecond then
				player:SetAttribute("PerSecond", perSecond)
			end
			if perSecond > 0 then
				local treats = getTreats(player)
				if treats then
					local earned = perSecond * TICK * boostFor(state, os.clock())
					treats.Value += earned
					state.totalEarned += earned
					player:SetAttribute("TotalEarned", state.totalEarned)
				end
			end
		end
	end
end)

-- ============================ LEADERBOARD (Stage 5) ============================

local leaderStore: OrderedDataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore("CatClickerLeaderboard_v1")
	end)
	if ok then
		leaderStore = result
	else
		warn("[CatClicker] Leaderboard DataStore unavailable: " .. tostring(result))
	end
end

local nameCache: { [number]: string } = {}

local function nameFor(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local online = Players:GetPlayerByUserId(userId)
	if online then
		nameCache[userId] = online.DisplayName
		return online.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or "???"
	return nameCache[userId]
end

local function saveScore(player: Player)
	local state = states[player]
	if leaderStore and state and state.totalEarned >= 1 then
		pcall(function()
			(leaderStore :: OrderedDataStore):SetAsync(tostring(player.UserId), math.floor(state.totalEarned))
		end)
	end
end

task.spawn(function()
	while true do
		-- Push everyone's scores, then broadcast the top 10
		for player in states do
			saveScore(player)
		end
		if leaderStore then
			local ok, pages = pcall(function()
				return (leaderStore :: OrderedDataStore):GetSortedAsync(false, 10)
			end)
			if ok then
				local top = {}
				for _, entry in pages:GetCurrentPage() do
					table.insert(top, {
						name = nameFor(tonumber(entry.key) :: number),
						score = entry.value,
					})
				end
				leaderboardSync:FireAllClients(top)
			end
		end
		task.wait(30)
	end
end)

Players.PlayerRemoving:Connect(saveScore)

print("[CatClicker] Server ready — stages 1-5")

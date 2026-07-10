--!strict
-- Cat Clicker server — Stages 1-2: click mechanic + generator shop.
-- Owns the Treats leaderstat, validates clicks and purchases, and pays out
-- passive Treats-per-second from owned generators.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

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

local offlineNotify = Instance.new("RemoteEvent")
offlineNotify.Name = "OfflineEarnings"
offlineNotify.Parent = ReplicatedStorage

local petSync = Instance.new("RemoteEvent")
petSync.Name = "PetSync"
petSync.Parent = ReplicatedStorage

local openEggFn = Instance.new("RemoteFunction")
openEggFn.Name = "OpenEgg"
openEggFn.Parent = ReplicatedStorage

local equipPetFn = Instance.new("RemoteFunction")
equipPetFn.Name = "EquipPet"
equipPetFn.Parent = ReplicatedStorage

local dailyStateFn = Instance.new("RemoteFunction")
dailyStateFn.Name = "DailyState"
dailyStateFn.Parent = ReplicatedStorage

local checkInFn = Instance.new("RemoteFunction")
checkInFn.Name = "CheckIn"
checkInFn.Parent = ReplicatedStorage

local spinFn = Instance.new("RemoteFunction")
spinFn.Name = "SpinWheel"
spinFn.Parent = ReplicatedStorage

local globalEvent = Instance.new("RemoteEvent")
globalEvent.Name = "GlobalEvent"
globalEvent.Parent = ReplicatedStorage

local leaderboardSync = Instance.new("RemoteEvent")
leaderboardSync.Name = "LeaderboardSync"
leaderboardSync.Parent = ReplicatedStorage

local rebirthFn = Instance.new("RemoteFunction")
rebirthFn.Name = "Rebirth"
rebirthFn.Parent = ReplicatedStorage

local redeemFn = Instance.new("RemoteFunction")
redeemFn.Name = "RedeemCode"
redeemFn.Parent = ReplicatedStorage

local resetFn = Instance.new("RemoteFunction")
resetFn.Name = "ResetSave"
resetFn.Parent = ReplicatedStorage

local savedNotify = Instance.new("RemoteEvent")
savedNotify.Name = "SavedNotify"
savedNotify.Parent = ReplicatedStorage

local goldenRng = Random.new()

type PlayerState = {
	clickTokens: number, -- token bucket: refills at MaxClicksPerSecond
	lastRefill: number,
	counts: { [string]: number }, -- generatorId -> owned
	clickUpgrades: { [string]: boolean }, -- upgradeId -> owned
	nextGoldenAt: number,
	goldenOfferExpires: number?,
	goldenOfferType: string?,
	boostMult: number,
	boostEnds: number,
	discountEnds: number, -- Money Cat: half-price shop until this time
	totalEarned: number,
	clicks: number,
	loaded: boolean, -- save data applied (or confirmed new player)
	loading: boolean, -- load in progress
	persist: boolean, -- false if load failed: never overwrite their data
	catPoints: number,
	redeemed: { [string]: boolean },
	joinedAt: number,
	playtimeBase: number, -- seconds from previous sessions
	pets: { [string]: number }, -- petId -> owned count
	equipped: { string }, -- up to Pets.MaxEquipped petIds
	pawCoins: number,
	lastCheckIn: number, -- day number (os.time()/86400)
	checkInStreak: number,
	lastSpin: number, -- day number
	vip: boolean,
}

local function prestigeBoost(state: PlayerState): number
	return 1 + state.catPoints * Config.Prestige.BoostPerPoint
end

local function petBoost(state: PlayerState): number
	local mult = 1
	for _, petId in state.equipped do
		local pet = Config.PetsById[petId]
		if pet then
			mult *= pet.mult
		end
	end
	return mult
end

local function vipBoost(state: PlayerState): number
	return state.vip and Config.Monetization.VipMultiplier or 1
end

-- Every permanent multiplier combined (specials handled separately)
local function permanentBoost(state: PlayerState): number
	return prestigeBoost(state) * petBoost(state) * vipBoost(state)
end

local function currentDay(): number
	return math.floor(os.time() / 86400)
end

-- Active global mutation event (nil when calm)
local activeEvent: any = nil
local activeEventEnds = 0

local function eventMult(): number
	if activeEvent and os.clock() < activeEventEnds then
		return activeEvent.allMult or 1
	end
	return 1
end

local function boostFor(state: PlayerState, now: number): number
	return now < state.boostEnds and state.boostMult or 1
end

local function discountedCost(state: PlayerState, cost: number): number
	if os.clock() < state.discountEnds then
		return math.floor(cost * 0.5)
	end
	return cost
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

-- Implemented in the persistence section (Stage 6); forward-declared so
-- the player add/remove handlers above them can call through.
local loadPlayerData: (Player) -> () = function() end
local savePlayerData: (Player) -> () = function() end

local function onPlayerAdded(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local treats = Instance.new("NumberValue")
	treats.Name = "Treats"
	treats.Value = 0
	treats.Parent = stats
	stats.Parent = player
	states[player] = {
		clickTokens = Config.MaxClicksPerSecond,
		lastRefill = os.clock(),
		counts = {},
		clickUpgrades = {},
		nextGoldenAt = os.clock()
			+ goldenRng:NextNumber(Config.SpecialCats.MinInterval, Config.SpecialCats.MaxInterval),
		goldenOfferExpires = nil,
		goldenOfferType = nil,
		boostMult = 1,
		boostEnds = 0,
		discountEnds = 0,
		totalEarned = 0,
		clicks = 0,
		loaded = false,
		loading = false,
		persist = false,
		catPoints = 0,
		redeemed = {},
		joinedAt = os.clock(),
		playtimeBase = 0,
		pets = {},
		equipped = {},
		pawCoins = 0,
		lastCheckIn = 0,
		checkInStreak = 0,
		lastSpin = 0,
		vip = false,
	}
	player:SetAttribute("PawCoins", 0)

	-- VIP gamepass check
	if Config.Monetization.VipGamePassId > 0 then
		task.spawn(function()
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.Monetization.VipGamePassId)
			end)
			local state = states[player]
			if ok and owns and state then
				state.vip = true
				player:SetAttribute("VIP", true)
			end
		end)
	end
	player:SetAttribute("TotalEarned", 0)
	player:SetAttribute("Clicks", 0)
	player:SetAttribute("PerSecond", 0)
	player:SetAttribute("CatPoints", 0)
	player:SetAttribute("PlaytimeBase", 0)
	task.spawn(loadPlayerData, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	states[player] = nil
end)

-- ============================ CLICKS (Stage 1) ============================

clickEvent.OnServerEvent:Connect(function(player)
	local treats = getTreats(player)
	local state = states[player]
	if not treats or not state then
		return
	end

	-- Token bucket: refills continuously, so overshooting the cap just
	-- skips single clicks instead of causing a multi-second dead window.
	local now = os.clock()
	state.clickTokens = math.min(Config.MaxClicksPerSecond,
		state.clickTokens + (now - state.lastRefill) * Config.MaxClicksPerSecond)
	state.lastRefill = now
	if state.clickTokens < 1 then
		return
	end
	state.clickTokens -= 1

	local gained = Config.ClickAmount(state.clickUpgrades) * boostFor(state, now)
		* permanentBoost(state) * eventMult()
	treats.Value += gained
	state.totalEarned += gained
	state.clicks += 1
	player:SetAttribute("TotalEarned", state.totalEarned)
	player:SetAttribute("Clicks", state.clicks)
	clickEvent:FireClient(player, gained)
end)

-- ============================ SPECIAL CATS ============================

local totalWeight = 0
for _, catType in Config.SpecialCats.Types do
	totalWeight += catType.weight
end

local function pickCatType(): any
	local roll = goldenRng:NextNumber(0, totalWeight)
	for _, catType in Config.SpecialCats.Types do
		roll -= catType.weight
		if roll <= 0 then
			return catType
		end
	end
	return Config.SpecialCats.Types[1]
end

goldenClick.OnServerEvent:Connect(function(player)
	local state = states[player]
	if not state then
		return
	end
	local now = os.clock()
	if not state.goldenOfferExpires or now > state.goldenOfferExpires :: number then
		return -- no special cat was live; ignore
	end
	local catType = Config.SpecialCatsById[state.goldenOfferType or ""]
	state.goldenOfferExpires = nil
	state.goldenOfferType = nil
	if not catType then
		return
	end

	if catType.discount then
		state.discountEnds = now + catType.duration
		boostSync:FireClient(player, "discount", catType.id, 0.5, catType.duration)
	else
		local duration = goldenRng:NextNumber(catType.minDur, catType.maxDur)
		state.boostMult = catType.boost
		state.boostEnds = now + duration
		boostSync:FireClient(player, "boost", catType.id, catType.boost, duration)
	end
end)

-- Spawner: offers each player a random special cat on their own schedule
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for player, state in states do
			if state.goldenOfferExpires and now > state.goldenOfferExpires :: number then
				state.goldenOfferExpires = nil
				state.goldenOfferType = nil
			end
			if not state.goldenOfferExpires and now >= state.nextGoldenAt then
				local catType = pickCatType()
				state.goldenOfferExpires = now + Config.SpecialCats.ClickWindow
				state.goldenOfferType = catType.id
				state.nextGoldenAt = now + Config.SpecialCats.ClickWindow
					+ goldenRng:NextNumber(Config.SpecialCats.MinInterval, Config.SpecialCats.MaxInterval)
				goldenOffer:FireClient(player, catType.id, Config.SpecialCats.ClickWindow)
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
	local cost = discountedCost(state, upgrade.cost)
	if treats.Value < cost then
		return
	end

	treats.Value -= cost
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
	local cost = discountedCost(state, Config.CostFor(gen, owned))
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
			perSecond *= permanentBoost(state)
			if player:GetAttribute("PerSecond") ~= perSecond then
				player:SetAttribute("PerSecond", perSecond)
			end
			if perSecond > 0 then
				local treats = getTreats(player)
				if treats then
					local earned = perSecond * TICK * boostFor(state, os.clock()) * eventMult()
					treats.Value += earned
					state.totalEarned += earned
					player:SetAttribute("TotalEarned", state.totalEarned)
				end
			end
		end
	end
end)

-- ============================ REBIRTH ============================

rebirthFn.OnServerInvoke = function(player)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats or not state.loaded then
		return false, "Not ready yet, try again!"
	end
	local points = math.floor(treats.Value / Config.Prestige.Threshold)
	if points < 1 then
		return false, "You need at least 500,000 treats to rebirth!"
	end

	local coins = points * Config.Prestige.CoinsPerPoint
		* (state.vip and Config.Monetization.VipCoinMultiplier or 1)
	treats.Value = 0
	state.catPoints += points
	state.pawCoins += coins
	player:SetAttribute("CatPoints", state.catPoints)
	player:SetAttribute("PawCoins", state.pawCoins)
	task.spawn(savePlayerData, player)
	return true, points, coins
end

-- ============================ CODES ============================

redeemFn.OnServerInvoke = function(player, code)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats or not state.loaded then
		return false, "Not ready yet, try again!"
	end
	if type(code) ~= "string" then
		return false, "Invalid code."
	end
	code = code:upper():gsub("%s+", "")
	local reward = Config.Codes[code]
	if not reward then
		return false, "Invalid code."
	end
	if state.redeemed[code] then
		return false, "You already redeemed that code!"
	end

	state.redeemed[code] = true
	treats.Value += reward.treats
	state.totalEarned += reward.treats
	player:SetAttribute("TotalEarned", state.totalEarned)
	return true, "+" .. reward.treats .. " treats! Enjoy 🐱"
end

-- ============================ PETS & EGGS ============================

local function syncPets(player: Player)
	local state = states[player]
	if state then
		petSync:FireClient(player, { pets = state.pets, equipped = state.equipped })
	end
end

local petTotalWeight = 0
for _, pet in Config.Pets.List do
	petTotalWeight += pet.weight
end

openEggFn.OnServerInvoke = function(player)
	local state = states[player]
	if not state or not state.loaded then
		return false, "Not ready yet!"
	end
	if state.pawCoins < Config.Pets.EggCost then
		return false, ("You need %d Paw Coins! Rebirth or claim dailies to earn them."):format(Config.Pets.EggCost)
	end

	state.pawCoins -= Config.Pets.EggCost
	player:SetAttribute("PawCoins", state.pawCoins)

	local roll = goldenRng:NextNumber(0, petTotalWeight)
	local hatched = Config.Pets.List[1]
	for _, pet in Config.Pets.List do
		roll -= pet.weight
		if roll <= 0 then
			hatched = pet
			break
		end
	end

	state.pets[hatched.id] = (state.pets[hatched.id] or 0) + 1
	-- Auto-equip if there's room
	if #state.equipped < Config.Pets.MaxEquipped and not table.find(state.equipped, hatched.id) then
		table.insert(state.equipped, hatched.id)
	end
	syncPets(player)
	task.spawn(savePlayerData, player)
	return true, hatched.id
end

-- action: "add" equips one copy, "remove" unequips one copy.
-- Duplicates are allowed, capped by how many copies the player owns.
equipPetFn.OnServerInvoke = function(player, petId, action)
	local state = states[player]
	if not state or type(petId) ~= "string" or not Config.PetsById[petId] then
		return false
	end
	if action == "remove" then
		local index = table.find(state.equipped, petId)
		if index then
			table.remove(state.equipped, index)
		end
	else
		local owned = state.pets[petId] or 0
		local equippedCopies = 0
		for _, id in state.equipped do
			if id == petId then
				equippedCopies += 1
			end
		end
		if equippedCopies >= owned then
			return false, "You don't own another copy — open more eggs!"
		end
		if #state.equipped >= Config.Pets.MaxEquipped then
			return false, "Max " .. Config.Pets.MaxEquipped .. " pets equipped!"
		end
		table.insert(state.equipped, petId)
	end
	syncPets(player)
	return true
end

petSync.OnServerEvent:Connect(syncPets) -- client requests its pets on load

-- ============================ DAILY REWARDS ============================

local function applyTimedBoost(player: Player, state: PlayerState, mult: number, duration: number)
	state.boostMult = mult
	state.boostEnds = os.clock() + duration
	boostSync:FireClient(player, "boost", "golden", mult, duration)
end

dailyStateFn.OnServerInvoke = function(player)
	local state = states[player]
	if not state then
		return nil
	end
	local day = currentDay()
	return {
		canCheckIn = state.lastCheckIn < day,
		canSpin = state.lastSpin < day,
		streak = state.checkInStreak,
	}
end

checkInFn.OnServerInvoke = function(player)
	local state = states[player]
	if not state or not state.loaded then
		return false, "Not ready yet!"
	end
	local day = currentDay()
	if state.lastCheckIn >= day then
		return false, "Already claimed today — come back tomorrow!"
	end
	if state.lastCheckIn == day - 1 then
		state.checkInStreak += 1
	else
		state.checkInStreak = 1
	end
	state.lastCheckIn = day

	local coins = (Config.Daily.CheckInBaseCoins + (state.checkInStreak - 1) * Config.Daily.CheckInStreakBonus)
		* (state.vip and Config.Monetization.VipCoinMultiplier or 1)
	state.pawCoins += coins
	player:SetAttribute("PawCoins", state.pawCoins)
	task.spawn(savePlayerData, player)
	return true, coins, state.checkInStreak
end

local spinTotalWeight = 0
for _, prize in Config.Daily.SpinPrizes do
	spinTotalWeight += prize.weight
end

spinFn.OnServerInvoke = function(player)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats or not state.loaded then
		return false, "Not ready yet!"
	end
	local day = currentDay()
	if state.lastSpin >= day then
		return false, "Already spun today — come back tomorrow!"
	end
	state.lastSpin = day

	local roll = goldenRng:NextNumber(0, spinTotalWeight)
	local prizeIndex = 1
	for i, prize in Config.Daily.SpinPrizes do
		roll -= prize.weight
		if roll <= 0 then
			prizeIndex = i
			break
		end
	end

	local prize = Config.Daily.SpinPrizes[prizeIndex] :: any
	if prize.treats then
		treats.Value += prize.treats
		state.totalEarned += prize.treats
		player:SetAttribute("TotalEarned", state.totalEarned)
	end
	if prize.coins then
		state.pawCoins += prize.coins * (state.vip and Config.Monetization.VipCoinMultiplier or 1)
		player:SetAttribute("PawCoins", state.pawCoins)
	end
	if prize.boost then
		applyTimedBoost(player, state, prize.boost, prize.duration)
	end
	task.spawn(savePlayerData, player)
	return true, prizeIndex
end

-- ============================ MUTATION EVENTS ============================

-- Late joiners ask what's happening right now
globalEvent.OnServerEvent:Connect(function(player)
	if activeEvent and os.clock() < activeEventEnds then
		globalEvent:FireClient(player, activeEvent.id, activeEventEnds - os.clock())
	end
end)

task.spawn(function()
	while true do
		task.wait(goldenRng:NextNumber(Config.Events.MinInterval, Config.Events.MaxInterval))
		local event = Config.Events.Types[goldenRng:NextInteger(1, #Config.Events.Types)]
		activeEvent = event
		activeEventEnds = os.clock() + event.duration
		globalEvent:FireAllClients(event.id, event.duration)

		-- Shooting stars: shower everyone with special cats while it lasts
		if event.starShower then
			task.spawn(function()
				while os.clock() < activeEventEnds do
					for player, state in states do
						if not state.goldenOfferExpires then
							local catType = pickCatType()
							state.goldenOfferExpires = os.clock() + Config.SpecialCats.ClickWindow
							state.goldenOfferType = catType.id
							goldenOffer:FireClient(player, catType.id, Config.SpecialCats.ClickWindow)
						end
					end
					task.wait(15)
				end
			end)
		end

		task.wait(event.duration)
		activeEvent = nil
	end
end)

-- ============================ ROBUX STORE ============================

local productsById: { [number]: any } = {}
for _, product in Config.Monetization.Products do
	if product.id > 0 then
		productsById[product.id] = product
	end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local product = productsById[receiptInfo.ProductId]
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local state = player and states[player]
	local treats = player and getTreats(player)
	if not product or not player or not state or not treats then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local grant = product.grant
	if grant.treats then
		treats.Value += grant.treats
		state.totalEarned += grant.treats
		player:SetAttribute("TotalEarned", state.totalEarned)
	end
	if grant.coins then
		state.pawCoins += grant.coins
		player:SetAttribute("PawCoins", state.pawCoins)
	end
	if grant.rebirths then
		state.catPoints += grant.rebirths
		state.pawCoins += grant.rebirths * Config.Prestige.CoinsPerPoint
		player:SetAttribute("CatPoints", state.catPoints)
		player:SetAttribute("PawCoins", state.pawCoins)
	end
	if grant.boost then
		applyTimedBoost(player, state, grant.boost, grant.duration)
	end
	task.spawn(savePlayerData, player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	local state = states[player]
	if purchased and state and passId == Config.Monetization.VipGamePassId then
		state.vip = true
		player:SetAttribute("VIP", true)
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

-- ============================ SAVE DATA (Stage 6) ============================

local saveStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("CatClickerSave_v1")
	end)
	if ok then
		saveStore = result
	else
		warn("[CatClicker] Save DataStore unavailable, progress won't persist: " .. tostring(result))
	end
end

loadPlayerData = function(player: Player)
	local state = states[player]
	if not state or state.loaded or state.loading then
		return
	end
	state.loading = true

	local data: any = nil
	local success = false
	if saveStore then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return (saveStore :: DataStore):GetAsync("player_" .. player.UserId)
			end)
			if ok then
				success = true
				data = result
				break
			end
			task.wait(2 ^ attempt)
		end
	end

	state = states[player] -- player may have left while we yielded
	if not state then
		return
	end
	state.loading = false
	state.loaded = true
	-- Only allow future saves if the load actually worked; otherwise we'd
	-- risk overwriting good data with a fresh profile while DataStore is down.
	state.persist = success
	if not success then
		warn("[CatClicker] Failed to load data for " .. player.Name .. "; playing session-only")
	end

	if type(data) == "table" then
		local treats = getTreats(player)
		if treats then
			treats.Value = tonumber(data.treats) or 0
		end
		state.totalEarned = tonumber(data.totalEarned) or 0
		state.clicks = math.floor(tonumber(data.clicks) or 0)
		if type(data.counts) == "table" then
			for id, owned in data.counts do
				if Config.GeneratorsById[id] and type(owned) == "number" then
					state.counts[id] = math.floor(owned)
				end
			end
		end
		if type(data.clickUpgrades) == "table" then
			for id, has in data.clickUpgrades do
				if Config.ClickUpgradesById[id] and has == true then
					state.clickUpgrades[id] = true
				end
			end
		end
		state.catPoints = math.floor(tonumber(data.catPoints) or 0)
		if type(data.redeemed) == "table" then
			for code, has in data.redeemed do
				if type(code) == "string" and has == true then
					state.redeemed[code] = true
				end
			end
		end
		state.playtimeBase = tonumber(data.playtime) or 0
		state.pawCoins = math.floor(tonumber(data.pawCoins) or 0)
		state.lastCheckIn = math.floor(tonumber(data.lastCheckIn) or 0)
		state.checkInStreak = math.floor(tonumber(data.checkInStreak) or 0)
		state.lastSpin = math.floor(tonumber(data.lastSpin) or 0)
		if type(data.pets) == "table" then
			for id, count in data.pets do
				if Config.PetsById[id] and type(count) == "number" then
					state.pets[id] = math.floor(count)
				end
			end
		end
		if type(data.equipped) == "table" then
			local tally: { [string]: number } = {}
			for _, id in data.equipped do
				if type(id) == "string" and Config.PetsById[id]
					and (tally[id] or 0) < (state.pets[id] or 0)
					and #state.equipped < Config.Pets.MaxEquipped then
					tally[id] = (tally[id] or 0) + 1
					table.insert(state.equipped, id)
				end
			end
		end
		player:SetAttribute("PawCoins", state.pawCoins)
		syncPets(player)
		player:SetAttribute("TotalEarned", state.totalEarned)
		player:SetAttribute("Clicks", state.clicks)
		player:SetAttribute("CatPoints", state.catPoints)
		player:SetAttribute("PlaytimeBase", state.playtimeBase)
		syncShop(player)

		-- Offline earnings: pay out passive income for time away
		local savedAt = tonumber(data.savedAt)
		if savedAt and treats then
			local away = math.clamp(os.time() - savedAt, 0, Config.Offline.MaxHours * 3600)
			local perSecond = 0
			for _, gen in Config.Generators do
				perSecond += gen.rate * (state.counts[gen.id] or 0)
			end
			local offlineRate = state.vip and Config.Monetization.VipOfflineRate or Config.Offline.Rate
			local offline = perSecond * prestigeBoost(state) * offlineRate * away
			if offline >= 1 then
				treats.Value += offline
				state.totalEarned += offline
				player:SetAttribute("TotalEarned", state.totalEarned)
				-- Small delay so the client UI is listening before we fire
				task.delay(4, function()
					if player.Parent then
						offlineNotify:FireClient(player, math.floor(offline), math.floor(away / 60))
					end
				end)
			end
		end
	end
end

savePlayerData = function(player: Player)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats or not state.loaded or not state.persist or not saveStore then
		return
	end
	local payload = {
		treats = treats.Value,
		totalEarned = state.totalEarned,
		clicks = state.clicks,
		counts = state.counts,
		clickUpgrades = state.clickUpgrades,
		catPoints = state.catPoints,
		redeemed = state.redeemed,
		playtime = state.playtimeBase + (os.clock() - state.joinedAt),
		savedAt = os.time(),
		pets = state.pets,
		equipped = state.equipped,
		pawCoins = state.pawCoins,
		lastCheckIn = state.lastCheckIn,
		checkInStreak = state.checkInStreak,
		lastSpin = state.lastSpin,
	}
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(saveStore :: DataStore):SetAsync("player_" .. player.UserId, payload)
		end)
		if ok then
			if player.Parent then -- still in game: flash the "Saved!" indicator
				savedNotify:FireClient(player)
			end
			break
		end
		warn("[CatClicker] Save attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(err))
		task.wait(2)
	end
	saveScore(player)
end

-- Reset Save (testing): wipes the stored profile and the live session state
resetFn.OnServerInvoke = function(player)
	local state = states[player]
	local treats = getTreats(player)
	if not state or not treats then
		return false, "Not ready."
	end

	if saveStore then
		pcall(function()
			(saveStore :: DataStore):RemoveAsync("player_" .. player.UserId)
		end)
	end
	if leaderStore then
		pcall(function()
			(leaderStore :: OrderedDataStore):SetAsync(tostring(player.UserId), 0)
		end)
	end

	treats.Value = 0
	state.counts = {}
	state.clickUpgrades = {}
	state.totalEarned = 0
	state.clicks = 0
	state.catPoints = 0
	state.redeemed = {}
	state.playtimeBase = 0
	state.joinedAt = os.clock()
	state.boostMult = 1
	state.boostEnds = 0
	state.pets = {}
	state.equipped = {}
	state.pawCoins = 0
	state.lastCheckIn = 0
	state.checkInStreak = 0
	state.lastSpin = 0
	player:SetAttribute("PawCoins", 0)
	syncPets(player)
	player:SetAttribute("TotalEarned", 0)
	player:SetAttribute("Clicks", 0)
	player:SetAttribute("CatPoints", 0)
	player:SetAttribute("PlaytimeBase", 0)
	syncShop(player)
	return true, "Save wiped. Fresh start!"
end

-- Catch anyone who joined before the loader above was assigned
for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerData, player)
end

-- Autosave every 3 minutes
task.spawn(function()
	while true do
		task.wait(180)
		for player in states do
			task.spawn(savePlayerData, player)
		end
	end
end)

game:BindToClose(function()
	for player in states do
		savePlayerData(player)
	end
end)

print("[CatClicker] Server ready — stages 1-6 (full game)")

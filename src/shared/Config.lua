--!strict
-- Cat Clicker global config.

local Config = {
	TreatsPerClick = 2,

	-- Clicks per second the server accepts (continuous token-bucket refill).
	-- 12/s is above what fingers do on mobile but kneecaps autoclickers.
	MaxClicksPerSecond = 12,

	-- Click sound
	MeowSoundId = "rbxassetid://120055798442871",
	FallbackClickSound = "rbxasset://sounds/impact_water.mp3",
	ClickVolume = 0.5,

	-- ==================== YOUR CAT IMAGES ====================
	-- Upload each cat picture at create.roblox.com -> Creations ->
	-- Development Items -> Decals, then paste the ASSET id here as
	-- "rbxassetid://123456789". Empty = emoji fallback is used.
	Images = {
		MainCat = "rbxassetid://117495846657473", -- the fat orange chonker (main clicker cat)
		LoadingCat = "rbxassetid://117495846657473", -- loading screen
		Pets = {
			polite = "rbxassetid://105896381335508", -- white smiling "polite" cat
			sadcat = "rbxassetid://133446695623833", -- black cat
			munchkin = "rbxassetid://82591414328650", -- standing orange kitten
			chonker = "rbxassetid://117495846657473", -- fat orange cat
		},
	},

	-- Cost multiplier applied per owned copy of a generator
	CostGrowth = 1.14,

	-- Treats-per-second generators
	Generators = {
		{ id = "kitten", name = "Kitten", icon = "🐈", rate = 0.2, baseCost = 10 },
		{ id = "housecat", name = "House Cat", icon = "🐱", rate = 1.5, baseCost = 75 },
		{ id = "cafe", name = "Cat Cafe", icon = "☕", rate = 10, baseCost = 700 },
		{ id = "tower", name = "Cat Tree Tower", icon = "🗼", rate = 55, baseCost = 8000 },
		{ id = "shelter", name = "Cat Shelter", icon = "🏠", rate = 300, baseCost = 90000 },
		{ id = "farm", name = "Cattery Farm", icon = "🚜", rate = 1600, baseCost = 900000 },
		{ id = "temple", name = "Cat Temple", icon = "⛩️", rate = 9000, baseCost = 12000000 },
		{ id = "station", name = "Cat Space Station", icon = "🛸", rate = 52000, baseCost = 180000000 },
		{ id = "dimension", name = "Catnip Dimension", icon = "🌌", rate = 310000, baseCost = 2500000000 },
	},

	-- One-time click upgrades (a long ladder so there's always a next goal)
	ClickUpgrades = {
		{ id = "toebean", name = "Extra Toe Bean", icon = "🐾", cost = 50, add = 1 },
		{ id = "claws", name = "Sharp Claws", icon = "✂️", cost = 400, add = 3 },
		{ id = "laser", name = "Laser Pointer", icon = "🔴", cost = 2000, add = 6 },
		{ id = "doublepaws", name = "Double Paws", icon = "🙌", cost = 2500, mult = 2 },
		{ id = "tuna", name = "Tuna Feast", icon = "🐟", cost = 15000, add = 15 },
		{ id = "coffee", name = "Caffeinated Cat", icon = "☕", cost = 25000, mult = 2 },
		{ id = "catnip", name = "Catnip Frenzy", icon = "🌿", cost = 100000, mult = 2 },
		{ id = "titanium", name = "Titanium Beans", icon = "🔩", cost = 120000, add = 50 },
		{ id = "zoomies", name = "Zoomies Mode", icon = "💨", cost = 800000, mult = 3 },
		{ id = "goldpaw", name = "Golden Paws", icon = "🏆", cost = 5000000, add = 250 },
		{ id = "cosmic", name = "Cosmic Whiskers", icon = "🌟", cost = 20000000, mult = 5 },
		{ id = "thunder", name = "Thunder Claws", icon = "⚡", cost = 150000000, mult = 3 },
		{ id = "galaxy", name = "Galaxy Fur", icon = "🌌", cost = 1000000000, add = 5000 },
		{ id = "godcat", name = "GOD CAT MODE", icon = "😼", cost = 10000000000, mult = 10 },
	},

	-- Special bonus cats drifting across the screen
	SpecialCats = {
		MinInterval = 25,
		MaxInterval = 70,
		ClickWindow = 12,
		Types = {
			{ id = "silver", name = "Silver Cat", emoji = "🐱", weight = 45,
				boost = 3, minDur = 45, maxDur = 75, color = { 198, 204, 215 } },
			{ id = "golden", name = "Golden Cat", emoji = "😺", weight = 30,
				boost = 7, minDur = 30, maxDur = 60, color = { 255, 200, 90 } },
			{ id = "money", name = "Money Cat", emoji = "🤑", weight = 18,
				discount = 0.5, duration = 60, color = { 120, 210, 130 } },
			{ id = "diamond", name = "Diamond Cat", emoji = "💎", weight = 7,
				boost = 15, minDur = 15, maxDur = 25, color = { 140, 230, 255 } },
		},
	},

	-- Prestige / rebirth: easier and much stronger
	Prestige = {
		Threshold = 500000, -- treats per Cat Point
		BoostPerPoint = 0.25, -- +25% to ALL gains per point, forever
		CoinsPerPoint = 100, -- Paw Coins granted per point (buy eggs!)
		MaxPointsPerRebirth = 200, -- caps the runaway rebirth feedback loop
		MaxCatPoints = 5000,
	},

	-- Hard economy caps (prevents number overflow / corrupted saves)
	MaxTreats = 1e21,
	MaxPawCoins = 1e9,

	-- ==================== PETS & EGGS ====================
	-- Paw Coins 🪙 come from rebirths, daily rewards and the spinner.
	-- Eggs hatch a random meme cat that roams your screen and multiplies
	-- all treat gains. Equipped multipliers stack (multiply together).
	Pets = {
		EggCost = 100, -- Paw Coins per egg
		MaxEquipped = 10, -- duplicates allowed — stack those chonkers!
		List = {
			{ id = "polite", name = "Polite Cat", emoji = "😸", rarity = "Common",
				weight = 40, mult = 1.10 },
			{ id = "sadcat", name = "Sad Black Cat", emoji = "🐈‍⬛", rarity = "Rare",
				weight = 30, mult = 1.25 },
			{ id = "munchkin", name = "Munchkin Kitten", emoji = "🧡", rarity = "Epic",
				weight = 20, mult = 1.50 },
			{ id = "chonker", name = "THE CHONKER", emoji = "🐱", rarity = "Legendary",
				weight = 10, mult = 2.00 },
		},
	},

	RarityColors = {
		Common = Color3.fromRGB(160, 165, 175),
		Rare = Color3.fromRGB(80, 150, 255),
		Epic = Color3.fromRGB(190, 90, 255),
		Legendary = Color3.fromRGB(255, 178, 44),
	},

	-- ==================== DAILY REWARDS ====================
	Daily = {
		-- 7-day login calendar (loops; streak picks the day)
		CheckInRewards = {
			{ name = "500 Treats", icon = "🍪", treats = 500 },
			{ name = "150 Paw Coins", icon = "🪙", coins = 150 },
			{ name = "10K Treats", icon = "🍪", treats = 10000 },
			{ name = "x3 Boost (5 min)", icon = "🚀", boost = 3, duration = 300 },
			{ name = "500 Paw Coins", icon = "💰", coins = 500 },
			{ name = "100K Treats + x5 Boost", icon = "🎁", treats = 100000, boost = 5, duration = 300 },
			{ name = "MEGA: 1M Treats + 2K Coins + x10", icon = "👑",
				treats = 1000000, coins = 2000, boost = 10, duration = 300 },
		},
		SpinPrizes = { -- 8 wheel slices, weighted — big wins possible!
			{ name = "10K Treats", treats = 10000, weight = 22, icon = "🍪" },
			{ name = "250 Paw Coins", coins = 250, weight = 20, icon = "🪙" },
			{ name = "100K Treats", treats = 100000, weight = 16, icon = "🎂" },
			{ name = "x10 Boost (5 min)", boost = 10, duration = 300, weight = 12, icon = "🚀" },
			{ name = "1,000 Paw Coins", coins = 1000, weight = 12, icon = "💰" },
			{ name = "1M TREATS", treats = 1000000, weight = 8, icon = "🌟" },
			{ name = "FREE LEGENDARY PET", pet = "chonker", weight = 6, icon = "🐱" },
			{ name = "JACKPOT: 5K Coins + 5M Treats", coins = 5000, treats = 5000000, weight = 4, icon = "🎰" },
		},
	},

	-- ==================== POTIONS ====================
	-- Consumable buffs, bought with Treats or Paw Coins (in the Cat Shop)
	Potions = {
		{ id = "luck", name = "Luck Potion", icon = "🍀", costCoins = 400, duration = 600,
			desc = "x3 Epic & Legendary egg luck (10 min)" },
		{ id = "power", name = "Power Potion", icon = "⚡", costTreats = 75000, duration = 300,
			clickMult = 3, desc = "x3 click power (5 min)" },
		{ id = "golden", name = "Golden Potion", icon = "🌟", costCoins = 300, duration = 180,
			boost = 5, desc = "x5 ALL treats (3 min)" },
		{ id = "magnet", name = "Cat Magnet", icon = "🧲", costTreats = 150000, duration = 600,
			desc = "Special cats spawn 2x faster (10 min)" },
	},

	-- ==================== ROBUX STORE ====================
	-- Create these on create.roblox.com (guide in chat), then paste the ids.
	Monetization = {
		VipGamePassId = 1906188783, -- Game Pass: VIP (permanent perks below)
		VipMultiplier = 3, -- x3 ALL treat gains
		VipCoinMultiplier = 2, -- x2 Paw Coins from rebirths, check-ins & spins
		VipOfflineRate = 1.0, -- VIPs earn 100% while offline (others 50%)
		Products = { -- Developer Products (repeatable purchases)
			{ key = "treats_small", id = 3609011291, name = "50K Treats", icon = "🍪", grant = { treats = 50000 } },
			{ key = "treats_big", id = 3609011901, name = "500K Treats", icon = "🍪", grant = { treats = 500000 } },
			{ key = "coins_small", id = 3609012533, name = "150 Paw Coins", icon = "🪙", grant = { coins = 150 } },
			{ key = "coins_big", id = 3609012695, name = "1,000 Paw Coins", icon = "🪙", grant = { coins = 1000 } },
			{ key = "rebirth", id = 3609012863, name = "+1 Rebirth", icon = "🐾", grant = { rebirths = 1 } },
			{ key = "megaboost", id = 3609012955, name = "x5 Boost (10 min)", icon = "🚀", grant = { boost = 5, duration = 600 } },
		},
	},

	Codes = {
		MEOW = { treats = 100 },
		ORANGE = { treats = 500 },
		CHONK = { treats = 2500 },
		FATCAT = { treats = 10000 },
		MILLIONMEOWS = { treats = 50000 },
	},

	Offline = {
		Rate = 0.5,
		MaxHours = 8,
	},

	-- ==================== MUTATION EVENTS ====================
	-- Global world events that restyle the whole screen and buff everyone.
	Events = {
		FirstDelay = 50, -- first event shortly after the server starts
		MinInterval = 90, -- seconds between events (random in range)
		MaxInterval = 180,
		Types = {
			{ id = "acidrain", name = "ACID RAIN", emoji = "☢️", duration = 75,
				allMult = 2, color = { 120, 235, 90 },
				desc = "x2 ALL treats while it pours!" },
			{ id = "nightfall", name = "NIGHTFALL", emoji = "🌙", duration = 75,
				allMult = 2.5, color = { 90, 90, 200 },
				desc = "x2.5 ALL treats under the moon!" },
			{ id = "stars", name = "SHOOTING STARS", emoji = "🌠", duration = 60,
				allMult = 1.5, starShower = true, color = { 255, 220, 120 },
				desc = "x1.5 treats + special cats raining!" },
		},
	},

	-- Warm orange tabby palette 🍊
	Colors = {
		Background = Color3.fromRGB(255, 240, 222),
		Panel = Color3.fromRGB(255, 252, 246),
		PanelShadow = Color3.fromRGB(245, 205, 165),
		Pink = Color3.fromRGB(255, 168, 88),
		PinkDark = Color3.fromRGB(235, 120, 45),
		CatBody = Color3.fromRGB(233, 148, 72),
		CatStripe = Color3.fromRGB(205, 115, 45),
		CatBelly = Color3.fromRGB(248, 200, 150),
		CatInnerEar = Color3.fromRGB(240, 150, 130),
		Text = Color3.fromRGB(115, 70, 40),
		TextSoft = Color3.fromRGB(185, 140, 105),
		Accent = Color3.fromRGB(255, 178, 44),
	},
}

Config.GeneratorsById = {}
for _, gen in Config.Generators do
	Config.GeneratorsById[gen.id] = gen
end

Config.ClickUpgradesById = {}
for _, upgrade in Config.ClickUpgrades do
	Config.ClickUpgradesById[upgrade.id] = upgrade
end

Config.SpecialCatsById = {}
for _, catType in Config.SpecialCats.Types do
	Config.SpecialCatsById[catType.id] = catType
end

Config.PetsById = {}
for _, pet in Config.Pets.List do
	Config.PetsById[pet.id] = pet
end

Config.EventsById = {}
for _, event in Config.Events.Types do
	Config.EventsById[event.id] = event
end

Config.PotionsById = {}
for _, potion in Config.Potions do
	Config.PotionsById[potion.id] = potion
end

-- Shared big-number formatter (K, M, B, T, Qa, Qi, ...)
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No" }
function Config.FormatNumber(n: number): string
	n = math.floor(math.max(0, n))
	if n < 1000 then
		return tostring(n)
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	local pattern = scaled >= 100 and "%.0f%s" or (scaled >= 10 and "%.1f%s" or "%.2f%s")
	return string.format(pattern, scaled, SUFFIXES[tier + 1])
end

function Config.CostFor(gen, owned: number): number
	return math.floor(gen.baseCost * Config.CostGrowth ^ owned + 0.5)
end

function Config.ClickAmount(ownedUpgrades: { [string]: boolean }): number
	local base = Config.TreatsPerClick
	local mult = 1
	for _, upgrade in Config.ClickUpgrades do
		if ownedUpgrades[upgrade.id] then
			base += (upgrade :: any).add or 0
			mult *= (upgrade :: any).mult or 1
		end
	end
	return base * mult
end

return Config

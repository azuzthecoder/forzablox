--!strict
-- Cat Clicker global config.

local Config = {
	TreatsPerClick = 2,

	-- Clicks per second the server accepts (continuous token-bucket refill)
	MaxClicksPerSecond = 25,

	-- Click sound
	MeowSoundId = "rbxassetid://120055798442871",
	FallbackClickSound = "rbxasset://sounds/impact_water.mp3",
	ClickVolume = 0.5,

	-- ==================== YOUR CAT IMAGES ====================
	-- Upload each cat picture at create.roblox.com -> Creations ->
	-- Development Items -> Decals, then paste the ASSET id here as
	-- "rbxassetid://123456789". Empty = emoji fallback is used.
	Images = {
		MainCat = "rbxassetid://82591414328650", -- the fat orange chonker (main clicker cat)
		LoadingCat = "rbxassetid://82591414328650", -- loading screen
		Pets = {
			polite = "rbxassetid://117495846657473", -- white smiling "polite" cat
			sadcat = "rbxassetid://105896381335508", -- black cat
			munchkin = "rbxassetid://133446695623833", -- standing orange kitten
			chonker = "rbxassetid://82591414328650", -- fat orange cat
		},
	},

	-- Cost multiplier applied per owned copy of a generator
	CostGrowth = 1.12,

	-- Treats-per-second generators (cheaper + juicier)
	Generators = {
		{ id = "kitten", name = "Kitten", icon = "🐈", rate = 0.2, baseCost = 10 },
		{ id = "housecat", name = "House Cat", icon = "🐱", rate = 1.5, baseCost = 75 },
		{ id = "cafe", name = "Cat Cafe", icon = "☕", rate = 10, baseCost = 700 },
		{ id = "tower", name = "Cat Tree Tower", icon = "🗼", rate = 55, baseCost = 8000 },
		{ id = "shelter", name = "Cat Shelter", icon = "🏠", rate = 300, baseCost = 90000 },
		{ id = "farm", name = "Cattery Farm", icon = "🚜", rate = 1600, baseCost = 900000 },
		{ id = "temple", name = "Cat Temple", icon = "⛩️", rate = 9000, baseCost = 12000000 },
	},

	-- One-time click upgrades (cheaper, and more of them)
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
		{ id = "cosmic", name = "Cosmic Whiskers", icon = "🌟", cost = 20000000, mult = 5 },
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
	},

	-- ==================== PETS & EGGS ====================
	-- Paw Coins 🪙 come from rebirths, daily rewards and the spinner.
	-- Eggs hatch a random meme cat that roams your screen and multiplies
	-- all treat gains. Equipped multipliers stack (multiply together).
	Pets = {
		EggCost = 100, -- Paw Coins per egg
		MaxEquipped = 3,
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
		CheckInBaseCoins = 50, -- day 1; +25 more per consecutive day
		CheckInStreakBonus = 25,
		SpinPrizes = { -- weighted; the spinner picks one per day
			{ name = "500 Treats", treats = 500, weight = 24, icon = "🍪" },
			{ name = "2,500 Treats", treats = 2500, weight = 20, icon = "🍪" },
			{ name = "10,000 Treats", treats = 10000, weight = 10, icon = "🍪" },
			{ name = "25 Paw Coins", coins = 25, weight = 20, icon = "🪙" },
			{ name = "75 Paw Coins", coins = 75, weight = 12, icon = "🪙" },
			{ name = "200 Paw Coins", coins = 200, weight = 6, icon = "🪙" },
			{ name = "x3 Boost (2 min)", boost = 3, duration = 120, weight = 6, icon = "🚀" },
			{ name = "JACKPOT! 500 Coins", coins = 500, weight = 2, icon = "🎰" },
		},
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

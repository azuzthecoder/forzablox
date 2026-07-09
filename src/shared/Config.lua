--!strict
-- Cat Clicker global config.

local Config = {
	TreatsPerClick = 1,

	-- Clicks per second the server accepts. Refills continuously (token
	-- bucket) so fast clicking slows down smoothly instead of freezing.
	MaxClicksPerSecond = 25,

	-- Set to a real meow asset id (Toolbox -> search "cat meow" -> copy id)
	-- e.g. "rbxassetid://131961136". Fallback is a soft built-in pop.
	MeowSoundId = "",
	FallbackClickSound = "rbxasset://sounds/impact_water.mp3",
	ClickVolume = 0.35,

	-- Cost multiplier applied per owned copy of a generator
	CostGrowth = 1.15,

	-- Treats-per-second generators (Cookie Clicker style)
	Generators = {
		{ id = "kitten", name = "Kitten", icon = "🐈", rate = 0.1, baseCost = 15 },
		{ id = "housecat", name = "House Cat", icon = "🐱", rate = 1, baseCost = 100 },
		{ id = "cafe", name = "Cat Cafe", icon = "☕", rate = 8, baseCost = 1100 },
		{ id = "tower", name = "Cat Tree Tower", icon = "🗼", rate = 47, baseCost = 12000 },
		{ id = "shelter", name = "Cat Shelter", icon = "🏠", rate = 260, baseCost = 130000 },
		{ id = "farm", name = "Cattery Farm", icon = "🚜", rate = 1400, baseCost = 1400000 },
		{ id = "temple", name = "Cat Temple", icon = "⛩️", rate = 7800, baseCost = 20000000 },
	},

	-- One-time click upgrades. "add" raises base treats per click;
	-- "mult" multiplies the total afterwards.
	ClickUpgrades = {
		{ id = "toebean", name = "Extra Toe Bean", icon = "🐾", cost = 100, add = 1 },
		{ id = "claws", name = "Sharp Claws", icon = "✂️", cost = 750, add = 2 },
		{ id = "doublepaws", name = "Double Paws", icon = "🙌", cost = 5000, mult = 2 },
		{ id = "coffee", name = "Caffeinated Cat", icon = "☕", cost = 50000, mult = 2 },
		{ id = "titanium", name = "Titanium Beans", icon = "🔩", cost = 250000, add = 25 },
		{ id = "zoomies", name = "Zoomies Mode", icon = "💨", cost = 2000000, mult = 3 },
		{ id = "cosmic", name = "Cosmic Whiskers", icon = "🌟", cost = 50000000, mult = 5 },
	},

	-- Special bonus cats that drift across the screen. Weighted spawn:
	-- higher weight = more common. Boost cats multiply ALL treat gains;
	-- the Money Cat halves shop prices for a while instead.
	SpecialCats = {
		MinInterval = 25, -- seconds between spawns (random in range)
		MaxInterval = 70,
		ClickWindow = 12, -- how long a cat stays on screen
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

	-- Prestige / rebirth
	Prestige = {
		Threshold = 1000000, -- treats needed per Cat Point
		BoostPerPoint = 0.10, -- +10% to ALL treat gains per Cat Point, forever
	},

	-- Redeemable codes: CODE -> reward
	Codes = {
		MEOW = { treats = 100 },
		ORANGE = { treats = 500 },
		CHONK = { treats = 2500 },
		FATCAT = { treats = 10000 },
		MILLIONMEOWS = { treats = 50000 },
	},

	-- Offline earnings: you keep making treats while away, at OfflineRate
	-- of your normal per-second, up to OfflineMaxHours.
	Offline = {
		Rate = 0.5,
		MaxHours = 8,
	},

	-- Warm orange tabby palette 🍊
	Colors = {
		Background = Color3.fromRGB(255, 240, 222), -- warm cream
		Panel = Color3.fromRGB(255, 252, 246),
		PanelShadow = Color3.fromRGB(245, 205, 165),
		Pink = Color3.fromRGB(255, 168, 88), -- primary orange
		PinkDark = Color3.fromRGB(235, 120, 45), -- deep orange
		CatBody = Color3.fromRGB(233, 148, 72), -- orange tabby fur
		CatStripe = Color3.fromRGB(205, 115, 45), -- darker tabby stripes
		CatBelly = Color3.fromRGB(248, 200, 150), -- lighter chest fur
		CatInnerEar = Color3.fromRGB(240, 150, 130),
		Text = Color3.fromRGB(115, 70, 40),
		TextSoft = Color3.fromRGB(185, 140, 105),
		Accent = Color3.fromRGB(255, 178, 44), -- treat gold
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

-- Price of the next copy given how many are already owned
function Config.CostFor(gen, owned: number): number
	return math.floor(gen.baseCost * Config.CostGrowth ^ owned + 0.5)
end

-- Treats per click given a set of owned upgrade ids ({ [id] = true })
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

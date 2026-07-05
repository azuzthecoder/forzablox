--!strict
-- Cat Clicker global config.

local Config = {
	TreatsPerClick = 1,

	-- Max clicks per second the server will accept (anti-autoclick abuse)
	MaxClicksPerSecond = 20,

	-- Set to a real meow asset id (e.g. "rbxassetid://131961136") if you have
	-- one; the fallback below is a built-in Roblox sound so stage 1 always
	-- makes a noise.
	MeowSoundId = "",
	FallbackClickSound = "rbxasset://sounds/electronicpingshort.wav",

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

	-- One-time click upgrades (Cookie Clicker style). "add" raises the base
	-- treats per click; "mult" multiplies the total afterwards.
	ClickUpgrades = {
		{ id = "toebean", name = "Extra Toe Bean", icon = "🐾", cost = 100, add = 1 },
		{ id = "claws", name = "Sharp Claws", icon = "✂️", cost = 750, add = 2 },
		{ id = "doublepaws", name = "Double Paws", icon = "🙌", cost = 5000, mult = 2 },
		{ id = "coffee", name = "Caffeinated Cat", icon = "☕", cost = 50000, mult = 2 },
		{ id = "titanium", name = "Titanium Beans", icon = "🔩", cost = 250000, add = 25 },
		{ id = "zoomies", name = "Zoomies Mode", icon = "💨", cost = 2000000, mult = 3 },
		{ id = "cosmic", name = "Cosmic Whiskers", icon = "🌟", cost = 50000000, mult = 5 },
	},

	-- Pastel palette
	Colors = {
		Background = Color3.fromRGB(255, 241, 235), -- cream
		Panel = Color3.fromRGB(255, 255, 252),
		PanelShadow = Color3.fromRGB(240, 205, 200),
		Pink = Color3.fromRGB(255, 170, 195),
		PinkDark = Color3.fromRGB(235, 120, 155),
		CatBody = Color3.fromRGB(255, 214, 194), -- peachy cat
		CatInnerEar = Color3.fromRGB(255, 170, 185),
		Text = Color3.fromRGB(110, 80, 90),
		TextSoft = Color3.fromRGB(180, 140, 150),
		Accent = Color3.fromRGB(255, 200, 90), -- warm gold for treats
	},
}

Config.GeneratorsById = {}
for _, gen in Config.Generators do
	Config.GeneratorsById[gen.id] = gen
end

-- Price of the next copy given how many are already owned
function Config.CostFor(gen, owned: number): number
	return math.floor(gen.baseCost * Config.CostGrowth ^ owned + 0.5)
end

Config.ClickUpgradesById = {}
for _, upgrade in Config.ClickUpgrades do
	Config.ClickUpgradesById[upgrade.id] = upgrade
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

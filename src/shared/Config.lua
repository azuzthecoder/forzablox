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

return Config

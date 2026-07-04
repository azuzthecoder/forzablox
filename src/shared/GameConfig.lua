--!strict
-- Global tuning for ForzaBlox.

local GameConfig = {
	-- Economy
	StartingCredits = 60000,
	DataStoreName = "ForzaBlox_v1",

	-- Conversion: Roblox studs/second -> displayed MPH (1 stud ~ 1 foot)
	MphPerStudsPerSecond = 0.681818,

	-- Optional looping engine sound asset id (e.g. "rbxassetid://123456").
	-- Left empty by default so the game never depends on an asset that may
	-- not be available; set your own for engine audio.
	EngineSoundId = "",

	-- Cars
	MaxSpawnedCarsPerPlayer = 1,
	CarDespawnOnDeath = false,

	-- Races
	CheckpointRadius = 36,
	RaceTimeoutSeconds = 480,
}

return GameConfig

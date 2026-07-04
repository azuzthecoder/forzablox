--!strict
-- Player profiles: credits, owned cars, custom paint. Persists via DataStore
-- (gracefully degrades to session-only data when DataStores are unavailable,
-- e.g. in Studio without API access).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CarCatalog = require(Shared:WaitForChild("CarCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

export type Profile = {
	credits: number,
	owned: { [string]: boolean },
	colors: { [string]: { number } }, -- carId -> {r, g, b} (0-255)
	activeCar: string?,
}

local EconomyService = {}

local profiles: { [Player]: Profile } = {}
local store: DataStore? = nil

local profileUpdate: RemoteEvent
local notify: RemoteEvent

local STARTER_CAR = "pico_dash"

-- ============================ PERSISTENCE ============================

local function defaultProfile(): Profile
	return {
		credits = GameConfig.StartingCredits,
		owned = { [STARTER_CAR] = true },
		colors = {},
		activeCar = STARTER_CAR,
	}
end

local function loadProfile(player: Player): Profile
	if store then
		local ok, data = pcall(function()
			return (store :: DataStore):GetAsync("player_" .. player.UserId)
		end)
		if ok and type(data) == "table" then
			local profile = defaultProfile()
			if type(data.credits) == "number" then
				profile.credits = math.max(0, math.floor(data.credits))
			end
			if type(data.owned) == "table" then
				for carId, has in data.owned do
					if has == true and CarCatalog.Get(carId) then
						profile.owned[carId] = true
					end
				end
			end
			if type(data.colors) == "table" then
				profile.colors = data.colors
			end
			if type(data.activeCar) == "string" and profile.owned[data.activeCar] then
				profile.activeCar = data.activeCar
			end
			return profile
		end
	end
	return defaultProfile()
end

local function saveProfile(player: Player)
	local profile = profiles[player]
	if not profile or not store then
		return
	end
	pcall(function()
		(store :: DataStore):SetAsync("player_" .. player.UserId, {
			credits = profile.credits,
			owned = profile.owned,
			colors = profile.colors,
			activeCar = profile.activeCar,
		})
	end)
end

-- ============================ SYNC ============================

local function pushProfile(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local credits = stats:FindFirstChild("Credits") :: IntValue?
		if credits then
			credits.Value = profile.credits
		end
	end
	profileUpdate:FireClient(player, {
		credits = profile.credits,
		owned = profile.owned,
		colors = profile.colors,
		activeCar = profile.activeCar,
	})
end

-- ============================ PUBLIC API ============================

function EconomyService.GetProfile(player: Player): Profile?
	return profiles[player]
end

function EconomyService.AddCredits(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.credits = math.max(0, profile.credits + math.floor(amount))
	pushProfile(player)
end

function EconomyService.SetActiveCar(player: Player, carId: string)
	local profile = profiles[player]
	if profile and profile.owned[carId] then
		profile.activeCar = carId
		pushProfile(player)
	end
end

function EconomyService.SetCarColor(player: Player, carId: string, color: Color3)
	local profile = profiles[player]
	if profile and profile.owned[carId] then
		profile.colors[carId] = {
			math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255),
		}
		pushProfile(player)
	end
end

function EconomyService.GetCarColor(player: Player, carId: string): Color3?
	local profile = profiles[player]
	if profile then
		local raw = profile.colors[carId]
		if type(raw) == "table" and #raw == 3 then
			return Color3.fromRGB(raw[1], raw[2], raw[3])
		end
	end
	return nil
end

function EconomyService.Notify(player: Player, text: string, kind: string?)
	notify:FireClient(player, text, kind or "info")
end

-- ============================ HANDLERS ============================

local function handleBuyCar(player: Player, carId: unknown): (boolean, string)
	local profile = profiles[player]
	if not profile then
		return false, "Profile not loaded yet."
	end
	if type(carId) ~= "string" then
		return false, "Invalid request."
	end
	local def = CarCatalog.Get(carId)
	if not def then
		return false, "Unknown car."
	end
	if profile.owned[carId] then
		return false, "You already own the " .. def.name .. "."
	end
	if profile.credits < def.price then
		return false, "Not enough credits for the " .. def.name .. "."
	end

	profile.credits -= def.price
	profile.owned[carId] = true
	profile.activeCar = carId
	pushProfile(player)
	task.spawn(saveProfile, player)

	return true, "Congratulations! The " .. def.name .. " is yours."
end

-- ============================ INIT ============================

function EconomyService.Init()
	profileUpdate = Remotes.Get("ProfileUpdate") :: RemoteEvent
	notify = Remotes.Get("Notify") :: RemoteEvent

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[ForzaBlox] DataStores unavailable, progress will not save: " .. tostring(result))
	end

	local buyCar = Remotes.Get("BuyCar") :: RemoteFunction
	buyCar.OnServerInvoke = function(player, carId)
		return handleBuyCar(player, carId)
	end

	local function onPlayerAdded(player: Player)
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local credits = Instance.new("IntValue")
		credits.Name = "Credits"
		credits.Parent = stats
		stats.Parent = player

		profiles[player] = loadProfile(player)
		pushProfile(player)
		EconomyService.Notify(player,
			"Welcome to the Horizon Festival! Press G for your garage.", "success")
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		saveProfile(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		for player in profiles do
			saveProfile(player)
		end
	end)

	-- Periodic autosave
	task.spawn(function()
		while true do
			task.wait(120)
			for player in profiles do
				saveProfile(player)
			end
		end
	end)
end

return EconomyService

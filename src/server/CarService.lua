--!strict
-- Spawns and manages player cars. The chassis' network ownership is handed
-- to the driver so the client-side raycast suspension (CarController) can
-- simulate it smoothly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CarCatalog = require(Shared:WaitForChild("CarCatalog"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Layout = require(Shared:WaitForChild("MapLayout"))

type EconomyService = typeof(require(script.Parent.EconomyService))

local CarService = {}

local economy: EconomyService
local carsFolder: Folder
local playerCars: { [Player]: Model } = {}

-- ============================ HELPERS ============================

local function groundHeightAt(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { carsFolder }
	local result = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), params)
	if result then
		return result.Position.Y
	end
	return Layout.RoadY
end

local function findSpawnCFrame(player: Player): CFrame
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.05 then
			flat = Vector3.new(0, 0, -1)
		else
			flat = flat.Unit
		end
		local pos = root.Position + flat * 16
		local y = groundHeightAt(pos.X, pos.Z)
		return CFrame.lookAt(Vector3.new(pos.X, y + 4, pos.Z), Vector3.new(pos.X, y + 4, pos.Z) + flat)
	end
	-- Fall back to the hub car pad
	local pad = Layout.HubPosition + Vector3.new(-40, 0, 55)
	return CFrame.new(pad.X, Layout.RoadY + 4, pad.Z)
end

-- ============================ PUBLIC API ============================

function CarService.GetPlayerCar(player: Player): Model?
	local car = playerCars[player]
	if car and car.Parent then
		return car
	end
	return nil
end

function CarService.DespawnCar(player: Player)
	local car = playerCars[player]
	playerCars[player] = nil
	if car then
		car:Destroy()
	end
end

function CarService.TeleportCar(player: Player, cframe: CFrame): boolean
	local car = CarService.GetPlayerCar(player)
	local chassis = car and car.PrimaryPart
	if not car or not chassis then
		return false
	end
	car:PivotTo(cframe)
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
	return true
end

function CarService.SpawnCar(player: Player, carId: string)
	local profile = economy.GetProfile(player)
	if not profile then
		return
	end
	local def = CarCatalog.Get(carId)
	if not def then
		return
	end
	if not profile.owned[carId] then
		economy.Notify(player, "You don't own the " .. def.name .. " yet!", "error")
		return
	end

	CarService.DespawnCar(player)

	local color = economy.GetCarColor(player, carId)
	local car = CarBuilder.Build(def, color, false)
	car.Name = player.Name .. "_" .. carId
	car:SetAttribute("OwnerUserId", player.UserId)
	car:PivotTo(findSpawnCFrame(player))
	car.Parent = carsFolder

	local chassis = car.PrimaryPart :: BasePart
	chassis:SetNetworkOwner(player)

	-- Only the owner can take the driver's seat
	local prompt = chassis:FindFirstChild("EnterPrompt") :: ProximityPrompt?
	local seat = car:FindFirstChild("DriverSeat") :: Seat?
	if prompt and seat then
		prompt.Triggered:Connect(function(triggeredBy)
			if triggeredBy ~= player then
				economy.Notify(triggeredBy, "That's " .. player.DisplayName .. "'s car!", "error")
				return
			end
			local character = triggeredBy.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 and seat.Occupant == nil then
				seat:Sit(humanoid)
			end
		end)
	end

	playerCars[player] = car
	economy.SetActiveCar(player, carId)
	economy.Notify(player, def.name .. " delivered!", "success")
end

-- ============================ INIT ============================

function CarService.Init(economyService)
	economy = economyService

	carsFolder = Instance.new("Folder")
	carsFolder.Name = "PlayerCars"
	carsFolder.Parent = workspace

	local spawnCar = Remotes.Get("SpawnCar") :: RemoteEvent
	spawnCar.OnServerEvent:Connect(function(player, carId)
		if type(carId) == "string" then
			CarService.SpawnCar(player, carId)
		end
	end)

	local setCarColor = Remotes.Get("SetCarColor") :: RemoteEvent
	setCarColor.OnServerEvent:Connect(function(player, r, g, b)
		if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
			return
		end
		local color = Color3.fromRGB(
			math.clamp(math.floor(r), 0, 255),
			math.clamp(math.floor(g), 0, 255),
			math.clamp(math.floor(b), 0, 255)
		)
		local car = CarService.GetPlayerCar(player)
		if not car then
			return
		end
		local carId = car:GetAttribute("CarId")
		if type(carId) == "string" then
			CarBuilder.Repaint(car, color)
			economy.SetCarColor(player, carId, color)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		CarService.DespawnCar(player)
	end)
end

return CarService

--!strict
-- Solo time-trial races around the map. Race boards near the festival hub
-- start each event; the server validates checkpoint progress every frame
-- and pays out credits on the finish line.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Layout = require(Shared:WaitForChild("MapLayout"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local RaceService = {}

type Route = {
	id: string,
	name: string,
	description: string,
	start: CFrame,
	checkpoints: { Vector3 },
	parTime: number,
	reward: number,
	boardPosition: Vector3,
}

type ActiveRace = {
	route: Route,
	nextIndex: number,
	startedAt: number,
	countdownDone: boolean,
}

local economy
local carService
local raceUpdate: RemoteEvent
local activeRaces: { [Player]: ActiveRace } = {}

-- ============================ ROUTES ============================

local function ringPoint(degrees: number): Vector3
	local theta = math.rad(degrees)
	return Vector3.new(
		math.sin(theta) * Layout.RingRadius,
		Layout.RoadY,
		math.cos(theta) * Layout.RingRadius
	)
end

local function ringStart(degrees: number): CFrame
	local theta = math.rad(degrees)
	local pos = ringPoint(degrees) + Vector3.new(0, 3, 0)
	local tangent = Vector3.new(math.cos(theta), 0, -math.sin(theta))
	return CFrame.lookAt(pos, pos + tangent)
end

local function buildRoutes(): { Route }
	local routes: { Route } = {}

	-- 1) Full lap of the ring highway
	local lapCheckpoints = {}
	for deg = 30, 360, 30 do
		table.insert(lapCheckpoints, ringPoint(deg))
	end
	table.insert(routes, {
		id = "horizon_circuit",
		name = "Horizon Circuit",
		description = "One full lap of the ring highway.",
		start = ringStart(0),
		checkpoints = lapCheckpoints,
		parTime = 115,
		reward = 18000,
		boardPosition = ringPoint(0) + Vector3.new(0, 0, 20),
	})

	-- 2) Cross-country sprint straight through the festival on the E-W road
	local sprintCheckpoints = {}
	for x = -320, 440, 152 do
		table.insert(sprintCheckpoints, Vector3.new(x, Layout.RoadY, 0))
	end
	local sprintStartPos = Vector3.new(-Layout.RingRadius + 30, Layout.RoadY + 3, 0)
	table.insert(routes, {
		id = "festival_sprint",
		name = "Festival Sprint",
		description = "Flat-out west to east, straight through the hub.",
		start = CFrame.lookAt(sprintStartPos, sprintStartPos + Vector3.new(1, 0, 0)),
		checkpoints = sprintCheckpoints,
		parTime = 38,
		reward = 9000,
		boardPosition = sprintStartPos + Vector3.new(6, -3, 22),
	})

	-- 3) Half-moon along the west side of the ring
	local coastCheckpoints = {}
	for deg = 210, 330, 24 do
		table.insert(coastCheckpoints, ringPoint(deg))
	end
	table.insert(routes, {
		id = "sunset_run",
		name = "Sunset Run",
		description = "A scenic half-loop chasing the low sun.",
		start = ringStart(186),
		checkpoints = coastCheckpoints,
		parTime = 55,
		reward = 11000,
		boardPosition = ringPoint(186) + Vector3.new(-20, 0, 0),
	})

	return routes
end

-- ============================ RACE BOARDS ============================

local function buildBoard(parent: Instance, route: Route)
	local ground = route.boardPosition
	local post = Instance.new("Part")
	post.Anchored = true
	post.Size = Vector3.new(0.6, 7, 0.6)
	post.Color = Color3.fromRGB(40, 40, 48)
	post.Material = Enum.Material.Metal
	post.CFrame = CFrame.new(ground.X, ground.Y + 3.5, ground.Z)
	post.Parent = parent

	local board = Instance.new("Part")
	board.Anchored = true
	board.Size = Vector3.new(9, 4.6, 0.5)
	board.Color = Color3.fromRGB(16, 18, 26)
	board.Material = Enum.Material.SmoothPlastic
	local toCenter = (Vector3.new(0, 0, 0) - Vector3.new(ground.X, 0, ground.Z))
	toCenter = Vector3.new(toCenter.X, 0, toCenter.Z).Unit
	board.CFrame = CFrame.lookAt(
		Vector3.new(ground.X, ground.Y + 8.2, ground.Z),
		Vector3.new(ground.X, ground.Y + 8.2, ground.Z) + toCenter
	)
	board.Parent = parent

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 24

		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(1, 0.42)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(0, 229, 255)
		title.Text = route.name
		title.Parent = gui

		local subtitle = Instance.new("TextLabel")
		subtitle.Position = UDim2.fromScale(0, 0.44)
		subtitle.Size = UDim2.fromScale(1, 0.3)
		subtitle.BackgroundTransparency = 1
		subtitle.Font = Enum.Font.Gotham
		subtitle.TextScaled = true
		subtitle.TextColor3 = Color3.fromRGB(220, 220, 228)
		subtitle.Text = route.description
		subtitle.Parent = gui

		local rewardLabel = Instance.new("TextLabel")
		rewardLabel.Position = UDim2.fromScale(0, 0.76)
		rewardLabel.Size = UDim2.fromScale(1, 0.22)
		rewardLabel.BackgroundTransparency = 1
		rewardLabel.Font = Enum.Font.GothamBold
		rewardLabel.TextScaled = true
		rewardLabel.TextColor3 = Color3.fromRGB(255, 202, 40)
		rewardLabel.Text = ("PAR %ds  •  UP TO %d CR"):format(route.parTime, math.floor(route.reward * 1.5))
		rewardLabel.Parent = gui

		gui.Parent = board
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Start Race"
	prompt.ObjectText = route.name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.Parent = post

	prompt.Triggered:Connect(function(player)
		RaceService.StartRace(player, route)
	end)
end

-- ============================ RACE FLOW ============================

function RaceService.StartRace(player: Player, route: Route)
	local car = carService.GetPlayerCar(player)
	if not car or not car.PrimaryPart then
		economy.Notify(player, "Spawn a car first! Press G to open your garage.", "error")
		return
	end

	activeRaces[player] = nil -- cancel any previous race silently

	carService.TeleportCar(player, route.start)

	raceUpdate:FireClient(player, {
		type = "prep",
		routeId = route.id,
		routeName = route.name,
		checkpoints = route.checkpoints,
		parTime = route.parTime,
		reward = route.reward,
	})

	task.spawn(function()
		for n = 3, 1, -1 do
			if not player.Parent then
				return
			end
			raceUpdate:FireClient(player, { type = "countdown", n = n })
			task.wait(1)
		end
		if not player.Parent or not carService.GetPlayerCar(player) then
			return
		end
		raceUpdate:FireClient(player, { type = "go" })
		activeRaces[player] = {
			route = route,
			nextIndex = 1,
			startedAt = os.clock(),
			countdownDone = true,
		}
	end)
end

local function finishRace(player: Player, race: ActiveRace)
	activeRaces[player] = nil
	local elapsed = os.clock() - race.startedAt
	local beatPar = elapsed <= race.route.parTime
	local reward = beatPar and math.floor(race.route.reward * 1.5) or race.route.reward
	economy.AddCredits(player, reward)
	raceUpdate:FireClient(player, {
		type = "finish",
		time = elapsed,
		parTime = race.route.parTime,
		beatPar = beatPar,
		reward = reward,
	})
	economy.Notify(player, ("%s complete! +%d CR"):format(race.route.name, reward), "success")
end

local function watchRaces()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, race in activeRaces do
			local car = carService.GetPlayerCar(player)
			local chassis = car and car.PrimaryPart
			if not chassis then
				activeRaces[player] = nil
				raceUpdate:FireClient(player, { type = "dnf", reason = "Your car despawned." })
				continue
			end

			if now - race.startedAt > GameConfig.RaceTimeoutSeconds then
				activeRaces[player] = nil
				raceUpdate:FireClient(player, { type = "dnf", reason = "Out of time!" })
				continue
			end

			local target = race.route.checkpoints[race.nextIndex]
			local delta = chassis.Position - target
			local flatDistance = Vector2.new(delta.X, delta.Z).Magnitude
			if flatDistance <= GameConfig.CheckpointRadius and math.abs(delta.Y) < 60 then
				race.nextIndex += 1
				if race.nextIndex > #race.route.checkpoints then
					finishRace(player, race)
				else
					raceUpdate:FireClient(player, {
						type = "checkpoint",
						index = race.nextIndex - 1,
						total = #race.route.checkpoints,
					})
				end
			end
		end
	end)
end

-- ============================ INIT ============================

function RaceService.Init(economyService, carServiceModule)
	economy = economyService
	carService = carServiceModule
	raceUpdate = Remotes.Get("RaceUpdate") :: RemoteEvent

	local folder = Instance.new("Folder")
	folder.Name = "RaceBoards"
	folder.Parent = workspace

	for _, route in buildRoutes() do
		buildBoard(folder, route)
	end

	Players.PlayerRemoving:Connect(function(player)
		activeRaces[player] = nil
	end)

	watchRaces()
end

return RaceService

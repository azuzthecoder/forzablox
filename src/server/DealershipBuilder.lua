--!strict
-- The ForzaBlox Autoshow: a glass showroom near the festival hub with
-- slowly rotating display cars. Walking up to the front desk (or any
-- display car) opens the dealership UI on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared:WaitForChild("MapLayout"))
local CarCatalog = require(Shared:WaitForChild("CarCatalog"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DealershipBuilder = {}

local FEATURED = { "kestrel_gt", "tempesta_v10", "apex_panther" }

local FLOOR_W = 96 -- along X
local FLOOR_D = 64 -- along Z
local WALL_H = 18

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function glassWall(parent: Instance, cf: CFrame, sizeXYZ: Vector3)
	local wall = makePart({
		Name = "GlassWall",
		Size = sizeXYZ,
		Color = Color3.fromRGB(140, 190, 210),
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Reflectance = 0.2,
		CFrame = cf,
	})
	wall.Parent = parent
end

function DealershipBuilder.Build()
	local openDealership = Remotes.Get("OpenDealership") :: RemoteEvent

	local folder = Instance.new("Folder")
	folder.Name = "Dealership"

	local base = Layout.DealershipPosition
	local center = Vector3.new(base.X, 0, base.Z)

	-- Polished showroom floor
	local floor = makePart({
		Name = "ShowroomFloor",
		Size = Vector3.new(FLOOR_W, 1.4, FLOOR_D),
		Color = Color3.fromRGB(228, 228, 234),
		Material = Enum.Material.Marble,
		Reflectance = 0.08,
		CFrame = CFrame.new(center.X, 0.7, center.Z),
	})
	floor.Parent = folder

	-- Roof slab
	local roof = makePart({
		Name = "Roof",
		Size = Vector3.new(FLOOR_W + 4, 1.6, FLOOR_D + 4),
		Color = Color3.fromRGB(34, 34, 40),
		Material = Enum.Material.Metal,
		CFrame = CFrame.new(center.X, WALL_H + 2.2, center.Z),
	})
	roof.Parent = folder

	-- Glass walls; the west wall (facing the hub) has an entrance gap
	glassWall(folder, CFrame.new(center.X, WALL_H / 2 + 1.4, center.Z - FLOOR_D / 2),
		Vector3.new(FLOOR_W, WALL_H, 1)) -- north
	glassWall(folder, CFrame.new(center.X, WALL_H / 2 + 1.4, center.Z + FLOOR_D / 2),
		Vector3.new(FLOOR_W, WALL_H, 1)) -- south
	glassWall(folder, CFrame.new(center.X + FLOOR_W / 2, WALL_H / 2 + 1.4, center.Z),
		Vector3.new(1, WALL_H, FLOOR_D)) -- east
	local gapWidth = 18
	local sideLen = (FLOOR_D - gapWidth) / 2
	glassWall(folder, CFrame.new(center.X - FLOOR_W / 2, WALL_H / 2 + 1.4, center.Z - (gapWidth / 2 + sideLen / 2)),
		Vector3.new(1, WALL_H, sideLen))
	glassWall(folder, CFrame.new(center.X - FLOOR_W / 2, WALL_H / 2 + 1.4, center.Z + (gapWidth / 2 + sideLen / 2)),
		Vector3.new(1, WALL_H, sideLen))

	-- Neon sign above the entrance
	local sign = makePart({
		Name = "DealershipSign",
		Size = Vector3.new(2, 5, 42),
		Color = Color3.fromRGB(0, 229, 255),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(center.X - FLOOR_W / 2 - 1, WALL_H + 5.5, center.Z),
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(10, 20, 30)
	label.Text = "FORZABLOX AUTOSHOW"
	label.Parent = gui
	gui.Parent = sign
	sign.Parent = folder

	-- Front desk with the browse prompt
	local desk = makePart({
		Name = "FrontDesk",
		Size = Vector3.new(8, 3.4, 3),
		Color = Color3.fromRGB(28, 28, 34),
		Material = Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(center.X - FLOOR_W / 2 + 12, 3.1, center.Z),
	})
	desk.Parent = folder

	local deskPrompt = Instance.new("ProximityPrompt")
	deskPrompt.ActionText = "Browse Cars"
	deskPrompt.ObjectText = "ForzaBlox Autoshow"
	deskPrompt.HoldDuration = 0
	deskPrompt.MaxActivationDistance = 12
	deskPrompt.RequiresLineOfSight = false
	deskPrompt.Parent = desk
	deskPrompt.Triggered:Connect(function(player)
		openDealership:FireClient(player)
	end)

	-- Rotating display pedestals with featured cars
	local displays: { { model: Model, base: CFrame } } = {}
	for i, carId in FEATURED do
		local def = CarCatalog.Get(carId)
		if not def then
			continue
		end

		local pedestalPos = Vector3.new(
			center.X + 14,
			0,
			center.Z + (i - 2) * (FLOOR_D / 3.2)
		)
		local pedestal = makePart({
			Name = "Pedestal",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 22, 22),
			Color = Color3.fromRGB(50, 50, 60),
			Material = Enum.Material.Metal,
			Reflectance = 0.15,
			CFrame = CFrame.new(pedestalPos.X, 2, pedestalPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		})
		pedestal.Parent = folder

		local glowRing = makePart({
			Name = "PedestalGlow",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 23, 23),
			Color = Color3.fromRGB(255, 62, 150),
			Material = Enum.Material.Neon,
			CanCollide = false,
			CFrame = CFrame.new(pedestalPos.X, 2.1, pedestalPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		})
		glowRing.Parent = folder

		local spot = Instance.new("SpotLight")
		spot.Angle = 70
		spot.Brightness = 3
		spot.Range = 26
		spot.Face = Enum.NormalId.Bottom
		local spotHolder = makePart({
			Name = "DisplayLight",
			Size = Vector3.new(1, 0.5, 1),
			Transparency = 1,
			CanCollide = false,
			CFrame = CFrame.new(pedestalPos.X, WALL_H, pedestalPos.Z),
		})
		spot.Parent = spotHolder
		spotHolder.Parent = folder

		local car = CarBuilder.Build(def, nil, true)
		local baseCF = CFrame.new(pedestalPos.X, 5.2, pedestalPos.Z)
		car:PivotTo(baseCF)
		car.Parent = folder

		local carPrompt = Instance.new("ProximityPrompt")
		carPrompt.ActionText = "Browse Cars"
		carPrompt.ObjectText = def.name
		carPrompt.HoldDuration = 0
		carPrompt.MaxActivationDistance = 16
		carPrompt.RequiresLineOfSight = false
		carPrompt.Parent = car.PrimaryPart
		carPrompt.Triggered:Connect(function(player)
			openDealership:FireClient(player)
		end)

		table.insert(displays, { model = car, base = baseCF })
	end

	-- Slow turntable rotation for the display cars
	local angle = 0
	RunService.Heartbeat:Connect(function(dt)
		angle += dt * 0.35
		for _, display in displays do
			display.model:PivotTo(display.base * CFrame.Angles(0, angle, 0))
		end
	end)

	folder.Parent = workspace
end

return DealershipBuilder

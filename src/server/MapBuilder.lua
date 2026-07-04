--!strict
-- Builds the ForzaBlox open world: rolling terrain with distant mountains,
-- a lake, the "Horizon" ring highway, two cross-country roads, the festival
-- hub plaza, street lighting, trees and rocks. Everything is generated from
-- code so the repo needs no binary place file.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapLayout"))

local MapBuilder = {}

local SEED = 1337
local CELL = 16 -- terrain column resolution in studs
local FLOOR_Y = -44 -- bottom of the world

local rng = Random.new(SEED)

-- ============================ HEIGHTMAP ============================

local function rawHeight(x: number, z: number): number
	local n = 0
	n += math.noise(x / 320 + SEED, z / 320 - SEED) * 34
	n += math.noise(x / 96, z / 96, SEED) * 10
	n += math.noise(x / 30, z / 30, SEED * 2) * 3

	local d = math.sqrt(x * x + z * z)

	-- Mountain ring beyond the highway
	if d > 640 then
		n += (d - 640) * 0.22 * (0.75 + 0.5 * math.noise(x / 220, z / 220, 7))
	end

	-- Flatten under/near the ring road, the hub, and the two cross roads
	local ringFlat = math.clamp((math.abs(d - Layout.RingRadius) - Layout.RoadWidth) / 70, 0, 1)
	local hubFlat = math.clamp((d - Layout.HubRadius - 40) / 120, 0, 1)
	local damp = math.min(ringFlat, hubFlat)
	if d < Layout.RingRadius + 60 then
		local crossDist = math.min(math.abs(x), math.abs(z))
		damp = math.min(damp, math.clamp((crossDist - Layout.RoadWidth) / 60, 0, 1))
	end
	n *= damp

	-- Lake basin
	local lx = x - Layout.LakeCenter.X
	local lz = z - Layout.LakeCenter.Z
	local ld = math.sqrt(lx * lx + lz * lz)
	if ld < Layout.LakeRadius + 40 then
		n -= (1 - ld / (Layout.LakeRadius + 40)) * 28
	end

	return n
end

function MapBuilder.GetHeight(x: number, z: number): number
	return rawHeight(x, z)
end

local function materialFor(x: number, z: number, h: number): Enum.Material
	local lx = x - Layout.LakeCenter.X
	local lz = z - Layout.LakeCenter.Z
	local lakeDist = math.sqrt(lx * lx + lz * lz)
	if lakeDist < Layout.LakeRadius + 46 then
		return Enum.Material.Sand
	end
	if h > 46 then
		return Enum.Material.Rock
	end
	if h > 34 then
		return Enum.Material.Ground
	end
	if math.noise(x / 55 + 90, z / 55 - 90) > 0.32 then
		return Enum.Material.LeafyGrass
	end
	return Enum.Material.Grass
end

local function buildTerrain()
	local terrain = workspace.Terrain
	local half = Layout.MapHalfSize
	local cells = math.floor((half * 2) / CELL)

	for ix = 0, cells - 1 do
		local x = -half + ix * CELL + CELL / 2
		for iz = 0, cells - 1 do
			local z = -half + iz * CELL + CELL / 2
			local h = rawHeight(x, z)
			local top = math.max(h, FLOOR_Y + 8)
			local depth = top - FLOOR_Y
			terrain:FillBlock(
				CFrame.new(x, FLOOR_Y + depth / 2, z),
				Vector3.new(CELL, depth, CELL),
				materialFor(x, z, h)
			)
		end
		if ix % 12 == 0 then
			task.wait()
		end
	end

	-- Lake water
	terrain:FillCylinder(
		CFrame.new(Layout.LakeCenter.X, Layout.WaterLevel - 6, Layout.LakeCenter.Z),
		14,
		Layout.LakeRadius,
		Enum.Material.Water
	)
end

-- ============================ HELPERS ============================

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

local function addSignText(part: BasePart, text: string, face: Enum.NormalId, color: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.Parent = gui
	gui.Parent = part
end

-- ============================ ROADS ============================

local function buildStreetlight(parent: Instance, position: Vector3, faceAngle: number)
	local pole = makePart({
		Name = "LightPole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(13, 0.5, 0.5),
		Color = Color3.fromRGB(60, 62, 70),
		Material = Enum.Material.Metal,
		CFrame = CFrame.new(position + Vector3.new(0, 6.5, 0)) * CFrame.Angles(0, faceAngle, math.rad(90)),
	})
	pole.Parent = parent

	local lampPos = position + Vector3.new(0, 12.6, 0) + (CFrame.Angles(0, faceAngle, 0).LookVector * 3)
	local lamp = makePart({
		Name = "Lamp",
		Size = Vector3.new(1.6, 0.35, 0.9),
		Color = Color3.fromRGB(255, 236, 190),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(lampPos) * CFrame.Angles(0, faceAngle, 0),
	})
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 34
	light.Color = Color3.fromRGB(255, 226, 170)
	light.Parent = lamp
	lamp.Parent = parent

	local arm = makePart({
		Name = "LightArm",
		Size = Vector3.new(0.35, 0.35, 3.4),
		Color = Color3.fromRGB(60, 62, 70),
		Material = Enum.Material.Metal,
		CFrame = CFrame.new(position + Vector3.new(0, 12.8, 0) + CFrame.Angles(0, faceAngle, 0).LookVector * 1.5)
			* CFrame.Angles(0, faceAngle, 0),
	})
	arm.Parent = parent
end

local function buildRoadSegment(parent: Instance, cf: CFrame, length: number, dashed: boolean)
	local road = makePart({
		Name = "Road",
		Size = Vector3.new(Layout.RoadWidth, 1, length),
		Color = Color3.fromRGB(42, 42, 48),
		Material = Enum.Material.Asphalt,
		CFrame = cf * CFrame.new(0, -0.5 + Layout.RoadY, 0),
	})
	road.Parent = parent

	if dashed then
		local dash = makePart({
			Name = "LaneMarking",
			Size = Vector3.new(0.5, 0.06, length * 0.4),
			Color = Color3.fromRGB(235, 235, 225),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			CFrame = cf * CFrame.new(0, Layout.RoadY + 0.03, 0),
		})
		dash.Parent = parent
	end

	-- Edge lines
	for _, sideX in { -1, 1 } do
		local edge = makePart({
			Name = "EdgeLine",
			Size = Vector3.new(0.4, 0.06, length + 0.5),
			Color = Color3.fromRGB(230, 200, 90),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			CFrame = cf * CFrame.new(sideX * (Layout.RoadWidth / 2 - 0.6), Layout.RoadY + 0.03, 0),
		})
		edge.Parent = parent
	end
end

local function buildRingRoad(parent: Instance)
	local segments = 96
	local radius = Layout.RingRadius
	local segLength = (2 * math.pi * radius / segments) * 1.06

	for i = 0, segments - 1 do
		local theta = (i / segments) * 2 * math.pi
		local pos = Vector3.new(math.sin(theta) * radius, 0, math.cos(theta) * radius)
		local tangent = Vector3.new(math.cos(theta), 0, -math.sin(theta))
		local cf = CFrame.lookAt(pos, pos + tangent)
		buildRoadSegment(parent, cf, segLength, i % 2 == 0)

		if i % 6 == 0 then
			local inward = -pos.Unit
			local lightPos = pos + inward * (Layout.RoadWidth / 2 + 3)
			buildStreetlight(parent, Vector3.new(lightPos.X, Layout.RoadY, lightPos.Z),
				math.atan2(inward.X, inward.Z) + math.pi)
		end
	end
end

local function buildCrossRoads(parent: Instance)
	local radius = Layout.RingRadius
	local segLength = 64
	local count = math.floor((radius * 2) / segLength)

	for i = 0, count - 1 do
		local offset = -radius + segLength / 2 + i * segLength
		-- East-west road (runs along X, at z = 0)
		buildRoadSegment(parent,
			CFrame.new(offset, 0, 0) * CFrame.Angles(0, math.rad(90), 0), segLength, i % 2 == 0)
		-- North-south road (runs along Z, at x = 0)
		buildRoadSegment(parent, CFrame.new(0, 0, offset), segLength, i % 2 == 0)
	end
end

-- ============================ FESTIVAL HUB ============================

local function buildHub(parent: Instance)
	local hubPos = Layout.HubPosition

	-- Plaza disc
	local plaza = makePart({
		Name = "FestivalPlaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, Layout.HubRadius * 2, Layout.HubRadius * 2),
		Color = Color3.fromRGB(78, 78, 88),
		Material = Enum.Material.Concrete,
		CFrame = CFrame.new(hubPos.X, 0.55, hubPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
	})
	plaza.Parent = parent

	-- Neon festival ring painted on the plaza
	local ring = makePart({
		Name = "FestivalRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 70, 70),
		Color = Color3.fromRGB(255, 62, 150),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CFrame = CFrame.new(hubPos.X, 1.18, hubPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
	})
	ring.Parent = parent
	local ringInner = makePart({
		Name = "FestivalRingInner",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.22, 62, 62),
		Color = Color3.fromRGB(78, 78, 88),
		Material = Enum.Material.Concrete,
		CanCollide = false,
		CFrame = CFrame.new(hubPos.X, 1.19, hubPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
	})
	ringInner.Parent = parent

	-- Welcome arch over the plaza entrance (west side)
	local archX = hubPos.X - 90
	for _, sideZ in { -14, 14 } do
		local pillar = makePart({
			Name = "ArchPillar",
			Size = Vector3.new(3, 26, 3),
			Color = Color3.fromRGB(30, 30, 36),
			Material = Enum.Material.Metal,
			CFrame = CFrame.new(archX, 13, hubPos.Z + sideZ),
		})
		pillar.Parent = parent
	end
	local beam = makePart({
		Name = "ArchBeam",
		Size = Vector3.new(3.4, 6, 34),
		Color = Color3.fromRGB(255, 62, 150),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(archX, 28, hubPos.Z),
	})
	addSignText(beam, "FORZABLOX", Enum.NormalId.Left, Color3.fromRGB(255, 255, 255))
	addSignText(beam, "FORZABLOX", Enum.NormalId.Right, Color3.fromRGB(255, 255, 255))
	beam.Parent = parent

	-- Main stage (north side)
	local stageBase = makePart({
		Name = "Stage",
		Size = Vector3.new(46, 4, 20),
		Color = Color3.fromRGB(32, 32, 40),
		Material = Enum.Material.Metal,
		CFrame = CFrame.new(hubPos.X, 3, hubPos.Z - 100),
	})
	stageBase.Parent = parent
	local stageBack = makePart({
		Name = "StageBackdrop",
		Size = Vector3.new(46, 22, 2),
		Color = Color3.fromRGB(18, 18, 26),
		Material = Enum.Material.Metal,
		CFrame = CFrame.new(hubPos.X, 16, hubPos.Z - 109),
	})
	addSignText(stageBack, "HORIZON FESTIVAL", Enum.NormalId.Front, Color3.fromRGB(0, 229, 255))
	stageBack.Parent = parent
	for _, sideX in { -1, 1 } do
		local speaker = makePart({
			Name = "SpeakerStack",
			Size = Vector3.new(5, 12, 5),
			Color = Color3.fromRGB(14, 14, 18),
			Material = Enum.Material.Fabric,
			CFrame = CFrame.new(hubPos.X + sideX * 26, 7, hubPos.Z - 102),
		})
		speaker.Parent = parent
	end

	-- Festival tents (south side)
	for i = 1, 6 do
		local angle = math.rad(140 + i * 14)
		local dist = 95
		local tentPos = Vector3.new(hubPos.X + math.sin(angle) * dist, 0, hubPos.Z + math.cos(angle) * dist)
		local colors = {
			Color3.fromRGB(255, 62, 150), Color3.fromRGB(0, 229, 255), Color3.fromRGB(255, 202, 40),
		}
		local tent = Instance.new("WedgePart")
		tent.Anchored = true
		tent.Size = Vector3.new(10, 7, 12)
		tent.Color = colors[(i % 3) + 1]
		tent.Material = Enum.Material.Fabric
		tent.CFrame = CFrame.new(tentPos + Vector3.new(0, 4.6, 0)) * CFrame.Angles(0, angle, 0)
		tent.Parent = parent
	end

	-- Player spawns
	for i = 1, 4 do
		local angle = math.rad(i * 90 + 45)
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Size = Vector3.new(10, 1, 10)
		spawnLocation.Color = Color3.fromRGB(60, 60, 70)
		spawnLocation.Material = Enum.Material.Concrete
		spawnLocation.Anchored = true
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0
		spawnLocation.CFrame = CFrame.new(
			hubPos.X + math.sin(angle) * 45, 1.7, hubPos.Z + math.cos(angle) * 45)
		spawnLocation.Parent = parent
	end

	-- Car spawn pad marker (where CarService drops fresh cars)
	local pad = makePart({
		Name = "CarSpawnPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 30, 30),
		Color = Color3.fromRGB(0, 229, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.6,
		CanCollide = false,
		CFrame = CFrame.new(hubPos.X - 40, 1.25, hubPos.Z + 55) * CFrame.Angles(0, 0, math.rad(90)),
	})
	pad.Parent = parent
end

-- ============================ NATURE ============================

local function buildTree(parent: Instance, position: Vector3)
	local trunkHeight = rng:NextNumber(7, 13)
	local trunk = makePart({
		Name = "TreeTrunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(trunkHeight, 1.4, 1.4),
		Color = Color3.fromRGB(92, 66, 46),
		Material = Enum.Material.Wood,
		CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	trunk.Parent = parent

	local canopySize = rng:NextNumber(7, 11)
	for layer = 0, 1 do
		local ball = makePart({
			Name = "TreeCanopy",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (canopySize - layer * 3),
			Color = Color3.fromRGB(52 + rng:NextInteger(0, 30), 110 + rng:NextInteger(0, 40), 48),
			Material = Enum.Material.Grass,
			CanCollide = false,
			CFrame = CFrame.new(position + Vector3.new(
				rng:NextNumber(-1.5, 1.5), trunkHeight + layer * 3, rng:NextNumber(-1.5, 1.5))),
		})
		ball.Parent = parent
	end
end

local function scatterNature(parent: Instance)
	local placed = 0
	for _ = 1, 500 do
		if placed >= 170 then
			break
		end
		local x = rng:NextNumber(-900, 900)
		local z = rng:NextNumber(-900, 900)
		local d = math.sqrt(x * x + z * z)

		-- Keep clear of roads, hub, lake and dealership
		if math.abs(d - Layout.RingRadius) < 45 then continue end
		if d < Layout.HubRadius + 50 then continue end
		if d < Layout.RingRadius + 60 and math.min(math.abs(x), math.abs(z)) < 45 then continue end
		local lakeDX = x - Layout.LakeCenter.X
		local lakeDZ = z - Layout.LakeCenter.Z
		if math.sqrt(lakeDX * lakeDX + lakeDZ * lakeDZ) < Layout.LakeRadius + 40 then continue end

		local h = rawHeight(x, z)
		if h > 40 or h < -2 then continue end

		buildTree(parent, Vector3.new(x, h, z))
		placed += 1
	end

	-- Boulders in the foothills
	for _ = 1, 40 do
		local angle = rng:NextNumber(0, 2 * math.pi)
		local dist = rng:NextNumber(660, 950)
		local x = math.sin(angle) * dist
		local z = math.cos(angle) * dist
		local h = rawHeight(x, z)
		local sizeXYZ = rng:NextNumber(4, 12)
		local rock = makePart({
			Name = "Boulder",
			Size = Vector3.new(sizeXYZ, sizeXYZ * 0.8, sizeXYZ * 1.1),
			Color = Color3.fromRGB(110, 108, 116),
			Material = Enum.Material.Rock,
			CFrame = CFrame.new(x, h + sizeXYZ * 0.25, z)
				* CFrame.Angles(rng:NextNumber(0, 0.5), rng:NextNumber(0, math.pi), rng:NextNumber(0, 0.5)),
		})
		rock.Parent = parent
	end
end

-- ============================ ENTRY ============================

function MapBuilder.Build()
	-- Remove a default baseplate if the place has one
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "ForzaBloxWorld"

	local roads = Instance.new("Folder")
	roads.Name = "Roads"
	roads.Parent = world
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = world
	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	nature.Parent = world

	world.Parent = workspace

	buildTerrain()
	buildRingRoad(roads)
	buildCrossRoads(roads)
	buildHub(hub)
	scatterNature(nature)

	print("[ForzaBlox] World generated")
end

return MapBuilder

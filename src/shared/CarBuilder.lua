--!strict
-- Procedurally builds every ForzaBlox car out of parts, so the game needs no
-- external meshes or assets. Cars use a raycast-suspension physics model:
-- the chassis is the only real physics body, wheels are visual and are
-- positioned every frame by the client CarController via their welds.
--
-- Car convention: forward = -Z (Roblox LookVector).

local CarCatalog = require(script.Parent.CarCatalog)

local CarBuilder = {}

type StyleDef = {
	size: Vector3, -- chassis body (W, H, L)
	cabin: Vector3, -- glasshouse size
	cabinZ: number, -- cabin center along length (+Z = rear)
	hoodLen: number,
	rearLen: number,
	wheelRadius: number,
	wheelWidth: number,
	axleZ: number, -- axle distance from center
	ride: number, -- suspension rest length
}

local STYLES: { [string]: StyleDef } = {
	hatch = {
		size = Vector3.new(6.0, 1.5, 10.6), cabin = Vector3.new(5.2, 1.5, 5.4),
		cabinZ = 1.0, hoodLen = 2.6, rearLen = 1.2,
		wheelRadius = 1.2, wheelWidth = 0.9, axleZ = 3.6, ride = 1.9,
	},
	sedan = {
		size = Vector3.new(6.4, 1.5, 13.2), cabin = Vector3.new(5.5, 1.4, 5.8),
		cabinZ = 0.6, hoodLen = 3.4, rearLen = 2.8,
		wheelRadius = 1.3, wheelWidth = 1.0, axleZ = 4.6, ride = 2.0,
	},
	coupe = {
		size = Vector3.new(6.4, 1.35, 12.8), cabin = Vector3.new(5.3, 1.25, 5.2),
		cabinZ = 0.9, hoodLen = 3.8, rearLen = 2.6,
		wheelRadius = 1.35, wheelWidth = 1.1, axleZ = 4.4, ride = 1.9,
	},
	muscle = {
		size = Vector3.new(6.8, 1.6, 13.6), cabin = Vector3.new(5.6, 1.35, 5.0),
		cabinZ = 1.2, hoodLen = 4.4, rearLen = 3.0,
		wheelRadius = 1.4, wheelWidth = 1.2, axleZ = 4.8, ride = 2.1,
	},
	suv = {
		size = Vector3.new(7.0, 2.2, 13.0), cabin = Vector3.new(6.2, 1.8, 7.0),
		cabinZ = 0.8, hoodLen = 3.2, rearLen = 1.4,
		wheelRadius = 1.6, wheelWidth = 1.3, axleZ = 4.4, ride = 2.6,
	},
	super = {
		size = Vector3.new(6.8, 1.15, 13.4), cabin = Vector3.new(5.2, 1.05, 4.6),
		cabinZ = 0.4, hoodLen = 4.6, rearLen = 3.4,
		wheelRadius = 1.35, wheelWidth = 1.25, axleZ = 4.7, ride = 1.7,
	},
	hyper = {
		size = Vector3.new(7.0, 1.05, 13.8), cabin = Vector3.new(5.0, 1.0, 4.4),
		cabinZ = 0.2, hoodLen = 5.0, rearLen = 3.8,
		wheelRadius = 1.4, wheelWidth = 1.35, axleZ = 4.9, ride = 1.6,
	},
}

local function makePart(className: string, props: { [string]: any }): BasePart
	local part = Instance.new(className) :: BasePart
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function weldTo(chassis: BasePart, part: BasePart, offset: CFrame)
	part.CFrame = chassis.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = chassis
	weld.Part1 = part
	weld.Parent = part
end

function CarBuilder.Build(def: CarCatalog.CarDef, paintColor: Color3?, displayOnly: boolean?): Model
	local style = STYLES[def.bodyStyle] or STYLES.coupe
	local color = paintColor or def.defaultColor
	local size = style.size
	local halfH = size.Y / 2

	local model = Instance.new("Model")
	model.Name = "Car_" .. def.id
	model:SetAttribute("CarId", def.id)
	model:SetAttribute("DisplayOnly", displayOnly == true)

	-- ============================ CHASSIS ============================
	local chassis = makePart("Part", {
		Name = "Chassis",
		Size = size,
		Color = color,
		Material = Enum.Material.Metal,
		Reflectance = 0.12,
		CanCollide = true,
		CanQuery = true,
		Massless = false,
	})
	chassis.CustomPhysicalProperties = PhysicalProperties.new(0.85, 0.3, 0.4, 1, 1)
	chassis:SetAttribute("Paint", true)
	chassis:SetAttribute("TopSpeedStuds", def.topSpeedMph / 0.681818)
	chassis:SetAttribute("Power", def.power)
	chassis:SetAttribute("Grip", def.grip)
	chassis:SetAttribute("Brake", def.brake)
	chassis:SetAttribute("Drive", def.drive)
	chassis:SetAttribute("WheelRadius", style.wheelRadius)
	chassis:SetAttribute("Ride", style.ride)
	chassis.Parent = model
	model.PrimaryPart = chassis

	-- Suspension ray origins at the four corners of the chassis floor
	local trackX = size.X / 2 - 0.35
	for _, corner in { { "FL", -1, -1 }, { "FR", 1, -1 }, { "RL", -1, 1 }, { "RR", 1, 1 } } do
		local att = Instance.new("Attachment")
		att.Name = "Susp_" .. (corner[1] :: string)
		att.Position = Vector3.new((corner[2] :: number) * trackX, -halfH, (corner[3] :: number) * style.axleZ)
		att.Parent = chassis
	end

	-- ============================ BODYWORK ============================
	local bodyMaterial = Enum.Material.Metal
	local frontZ = -size.Z / 2
	local rearZ = size.Z / 2

	-- Hood (slopes down toward the nose)
	local hood = makePart("WedgePart", {
		Name = "Hood",
		Size = Vector3.new(size.X * 0.96, style.cabin.Y * 0.75, style.hoodLen),
		Color = color, Material = bodyMaterial, Reflectance = 0.12,
	})
	hood:SetAttribute("Paint", true)
	weldTo(chassis, hood, CFrame.new(0, halfH + style.cabin.Y * 0.375, frontZ + style.hoodLen / 2))
	hood.Parent = model

	-- Rear deck (slopes down toward the tail)
	local deck = makePart("WedgePart", {
		Name = "RearDeck",
		Size = Vector3.new(size.X * 0.96, style.cabin.Y * 0.7, style.rearLen),
		Color = color, Material = bodyMaterial, Reflectance = 0.12,
	})
	deck:SetAttribute("Paint", true)
	weldTo(chassis, deck,
		CFrame.new(0, halfH + style.cabin.Y * 0.35, rearZ - style.rearLen / 2) * CFrame.Angles(0, math.pi, 0))
	deck.Parent = model

	-- Cabin / glasshouse
	local cabin = makePart("Part", {
		Name = "Cabin",
		Size = style.cabin,
		Color = Color3.fromRGB(24, 30, 38),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		Reflectance = 0.25,
		CanCollide = true,
	})
	weldTo(chassis, cabin, CFrame.new(0, halfH + style.cabin.Y / 2, style.cabinZ))
	cabin.Parent = model

	-- Windshield wedge in front of the cabin
	local shield = makePart("WedgePart", {
		Name = "Windshield",
		Size = Vector3.new(style.cabin.X, style.cabin.Y, 1.6),
		Color = Color3.fromRGB(24, 30, 38),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		Reflectance = 0.25,
	})
	weldTo(chassis, shield, CFrame.new(0, halfH + style.cabin.Y / 2, style.cabinZ - style.cabin.Z / 2 - 0.8))
	shield.Parent = model

	-- Rear glass wedge behind the cabin
	local rearGlass = makePart("WedgePart", {
		Name = "RearGlass",
		Size = Vector3.new(style.cabin.X, style.cabin.Y, 1.2),
		Color = Color3.fromRGB(24, 30, 38),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		Reflectance = 0.25,
	})
	weldTo(chassis, rearGlass,
		CFrame.new(0, halfH + style.cabin.Y / 2, style.cabinZ + style.cabin.Z / 2 + 0.6) * CFrame.Angles(0, math.pi, 0))
	rearGlass.Parent = model

	-- Bumpers and grille
	local frontBumper = makePart("Part", {
		Name = "FrontBumper",
		Size = Vector3.new(size.X, size.Y * 0.6, 0.6),
		Color = Color3.fromRGB(28, 28, 32), Material = Enum.Material.SmoothPlastic,
	})
	weldTo(chassis, frontBumper, CFrame.new(0, -size.Y * 0.15, frontZ - 0.25))
	frontBumper.Parent = model

	local rearBumper = frontBumper:Clone()
	rearBumper.Name = "RearBumper"
	weldTo(chassis, rearBumper, CFrame.new(0, -size.Y * 0.15, rearZ + 0.25))
	rearBumper.Parent = model

	local grille = makePart("Part", {
		Name = "Grille",
		Size = Vector3.new(size.X * 0.5, size.Y * 0.42, 0.15),
		Color = Color3.fromRGB(12, 12, 14), Material = Enum.Material.DiamondPlate,
	})
	weldTo(chassis, grille, CFrame.new(0, 0.05, frontZ - 0.5))
	grille.Parent = model

	-- Headlights / taillights (neon + real lights)
	for _, sideX in { -1, 1 } do
		local head = makePart("Part", {
			Name = "Headlight",
			Size = Vector3.new(size.X * 0.22, 0.35, 0.15),
			Color = Color3.fromRGB(235, 245, 255), Material = Enum.Material.Neon,
		})
		local spot = Instance.new("SpotLight")
		spot.Angle = 55
		spot.Brightness = 2.2
		spot.Range = 48
		spot.Face = Enum.NormalId.Back -- lights point along the part's -Z (car forward)
		spot.Color = Color3.fromRGB(255, 244, 220)
		spot.Parent = head
		weldTo(chassis, head, CFrame.new(sideX * size.X * 0.33, 0.35, frontZ - 0.5))
		head.Parent = model

		local tail = makePart("Part", {
			Name = "Taillight",
			Size = Vector3.new(size.X * 0.3, 0.3, 0.15),
			Color = Color3.fromRGB(255, 40, 40), Material = Enum.Material.Neon,
		})
		local glow = Instance.new("PointLight")
		glow.Brightness = 0.8
		glow.Range = 8
		glow.Color = Color3.fromRGB(255, 60, 60)
		glow.Parent = tail
		weldTo(chassis, tail, CFrame.new(sideX * size.X * 0.3, 0.3, rearZ + 0.5))
		tail.Parent = model
	end

	-- Exhausts
	for _, sideX in { -1, 1 } do
		local pipe = makePart("Part", {
			Name = "Exhaust",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.7, 0.45, 0.45),
			Color = Color3.fromRGB(160, 160, 168), Material = Enum.Material.Metal, Reflectance = 0.4,
		})
		weldTo(chassis, pipe,
			CFrame.new(sideX * size.X * 0.22, -halfH + 0.15, rearZ + 0.3) * CFrame.Angles(0, math.rad(90), 0))
		pipe.Parent = model
	end

	-- Spoiler
	if def.spoiler then
		local wing = makePart("Part", {
			Name = "Spoiler",
			Size = Vector3.new(size.X * 0.92, 0.18, 1.3),
			Color = Color3.fromRGB(22, 22, 26), Material = Enum.Material.SmoothPlastic,
		})
		weldTo(chassis, wing, CFrame.new(0, halfH + style.cabin.Y * 0.9, rearZ - 0.7))
		wing.Parent = model
		for _, sideX in { -1, 1 } do
			local stanchion = makePart("Part", {
				Name = "SpoilerMount",
				Size = Vector3.new(0.2, style.cabin.Y * 0.85, 0.5),
				Color = Color3.fromRGB(22, 22, 26), Material = Enum.Material.SmoothPlastic,
			})
			weldTo(chassis, stanchion, CFrame.new(sideX * size.X * 0.32, halfH + style.cabin.Y * 0.42, rearZ - 0.7))
			stanchion.Parent = model
		end
	end

	-- License plate
	local plate = makePart("Part", {
		Name = "Plate",
		Size = Vector3.new(1.8, 0.6, 0.1),
		Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.SmoothPlastic,
	})
	local plateGui = Instance.new("SurfaceGui")
	plateGui.Face = Enum.NormalId.Back
	plateGui.CanvasSize = Vector2.new(180, 60)
	local plateText = Instance.new("TextLabel")
	plateText.Size = UDim2.fromScale(1, 1)
	plateText.BackgroundTransparency = 1
	plateText.Font = Enum.Font.GothamBold
	plateText.TextScaled = true
	plateText.TextColor3 = Color3.fromRGB(30, 30, 40)
	plateText.Text = "FRZBLX"
	plateText.Parent = plateGui
	plateGui.Parent = plate
	weldTo(chassis, plate, CFrame.new(0, -0.1, rearZ + 0.56))
	plate.Parent = model

	-- ============================ WHEELS ============================
	for _, corner in { { "FL", -1, -1 }, { "FR", 1, -1 }, { "RL", -1, 1 }, { "RR", 1, 1 } } do
		local tag = corner[1] :: string
		local sx = corner[2] :: number
		local sz = corner[3] :: number

		local wheel = makePart("Part", {
			Name = "Wheel_" .. tag,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(style.wheelWidth, style.wheelRadius * 2, style.wheelRadius * 2),
			Color = Color3.fromRGB(18, 18, 20),
			Material = Enum.Material.Rubber :: any,
		})
		-- Rubber may not exist on old clients; fall back silently
		if wheel.Material ~= Enum.Material.Rubber then
			wheel.Material = Enum.Material.SmoothPlastic
		end

		local rim = makePart("Part", {
			Name = "Rim",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(style.wheelWidth + 0.05, style.wheelRadius * 1.15, style.wheelRadius * 1.15),
			Color = Color3.fromRGB(200, 204, 214),
			Material = Enum.Material.Metal,
			Reflectance = 0.35,
		})
		local rimWeld = Instance.new("WeldConstraint")
		rimWeld.Part0 = wheel
		rimWeld.Part1 = rim
		rimWeld.Parent = rim
		rim.CFrame = wheel.CFrame
		rim.Parent = wheel

		-- Wheel base position: hangs at rest length below the suspension corner
		local baseOffset = Vector3.new(
			sx * trackX,
			-halfH - (style.ride - style.wheelRadius),
			sz * style.axleZ
		)
		wheel.CFrame = chassis.CFrame * CFrame.new(baseOffset) * CFrame.Angles(0, 0, math.rad(90))

		local weld = Instance.new("Weld")
		weld.Name = "WheelWeld_" .. tag
		weld.Part0 = chassis
		weld.Part1 = wheel
		weld.C0 = CFrame.new(baseOffset) * CFrame.Angles(0, 0, math.rad(90))
		weld:SetAttribute("BaseOffset", baseOffset)
		weld:SetAttribute("Front", sz < 0)
		weld.Parent = chassis

		wheel.Parent = model
	end

	-- ============================ SEAT ============================
	if not displayOnly then
		local seat = Instance.new("Seat")
		seat.Name = "DriverSeat"
		seat.Size = Vector3.new(2, 0.4, 2)
		seat.Transparency = 1
		seat.CanCollide = false
		seat.CanTouch = true
		seat.Massless = true
		seat.CFrame = chassis.CFrame * CFrame.new(-1.1, halfH + 0.3, style.cabinZ)
		local seatWeld = Instance.new("WeldConstraint")
		seatWeld.Part0 = chassis
		seatWeld.Part1 = seat
		seatWeld.Parent = seat
		seat.Parent = model

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EnterPrompt"
		prompt.ActionText = "Drive"
		prompt.ObjectText = def.name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = chassis
	else
		-- Display cars are frozen in place
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end

	return model
end

-- Repaints every body panel of a built car.
function CarBuilder.Repaint(model: Model, color: Color3)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Paint") == true then
			part.Color = color
		end
	end
end

return CarBuilder

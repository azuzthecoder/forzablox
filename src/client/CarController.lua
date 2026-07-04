--!strict
-- Client-side driving model: raycast suspension with a simple tire model.
-- The chassis is the only physics body; each frame we cast a ray per wheel,
-- apply spring/damper + tire friction + drive impulses, and pose the visual
-- wheels through their welds. Runs only for the car we own and are sitting in
-- (the server gives us network ownership when it spawns our car).
--
-- Controls: W/S or arrows = throttle/brake+reverse, A/D = steer,
-- Space = handbrake (drift), R = flip car back over.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local CarController = {}

-- Telemetry read by the HUD / camera
CarController.Active = false
CarController.Chassis = nil :: BasePart?
CarController.SpeedMph = 0
CarController.SpeedFraction = 0
CarController.Gear = 1
CarController.Rpm = 0.15
CarController.Drifting = false
CarController.DriftScore = 0
CarController.InputLocked = false -- true during race countdowns

local player = Players.LocalPlayer

local GEARS = 6
local MAX_STEER = math.rad(33)
local REVERSE_TOP_SPEED = 38

type WheelInfo = {
	tag: string,
	weld: Weld,
	baseOffset: Vector3,
	front: boolean,
	attachment: Attachment,
	spin: number,
	compression: number,
}

type CarState = {
	model: Model,
	chassis: BasePart,
	seat: Seat,
	wheels: { WheelInfo },
	topSpeed: number,
	power: number,
	grip: number,
	brake: number,
	drive: string,
	ride: number,
	wheelRadius: number,
	steer: number, -- smoothed steering angle (radians, +left)
	rayParams: RaycastParams,
	engineSound: Sound?,
}

local current: CarState? = nil

-- ============================ INPUT ============================

local function readInput(): (number, number, boolean)
	if CarController.InputLocked or UserInputService:GetFocusedTextBox() then
		return 0, 0, false
	end
	local throttle = 0
	local steer = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		throttle += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		throttle -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		steer += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		steer -= 1
	end
	local handbrake = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	return throttle, steer, handbrake
end

-- ============================ ACTIVATION ============================

local function deactivate()
	local state = current
	current = nil
	CarController.Active = false
	CarController.Chassis = nil
	CarController.SpeedMph = 0
	CarController.SpeedFraction = 0
	CarController.Drifting = false
	if state and state.engineSound then
		state.engineSound:Stop()
	end
end

local function activate(seat: Seat)
	local model = seat.Parent
	if not model or not model:IsA("Model") then
		return
	end
	if model:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end
	local chassis = model.PrimaryPart
	if not chassis then
		return
	end

	local wheels: { WheelInfo } = {}
	for _, tag in { "FL", "FR", "RL", "RR" } do
		local weld = chassis:FindFirstChild("WheelWeld_" .. tag) :: Weld?
		local attachment = chassis:FindFirstChild("Susp_" .. tag) :: Attachment?
		if not weld or not attachment then
			return
		end
		table.insert(wheels, {
			tag = tag,
			weld = weld,
			baseOffset = weld:GetAttribute("BaseOffset") :: Vector3,
			front = weld:GetAttribute("Front") == true,
			attachment = attachment,
			spin = 0,
			compression = 0,
		})
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { model }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	rayParams.FilterDescendantsInstances = ignore

	local engineSound: Sound? = nil
	if GameConfig.EngineSoundId ~= "" then
		engineSound = Instance.new("Sound")
		engineSound.SoundId = GameConfig.EngineSoundId
		engineSound.Looped = true
		engineSound.Volume = 0.5
		engineSound.Parent = chassis
		engineSound:Play()
	end

	current = {
		model = model,
		chassis = chassis,
		seat = seat,
		wheels = wheels,
		topSpeed = (chassis:GetAttribute("TopSpeedStuds") :: number?) or 200,
		power = (chassis:GetAttribute("Power") :: number?) or 50,
		grip = (chassis:GetAttribute("Grip") :: number?) or 1.2,
		brake = (chassis:GetAttribute("Brake") :: number?) or 80,
		drive = (chassis:GetAttribute("Drive") :: string?) or "RWD",
		ride = (chassis:GetAttribute("Ride") :: number?) or 2,
		wheelRadius = (chassis:GetAttribute("WheelRadius") :: number?) or 1.4,
		steer = 0,
		rayParams = rayParams,
		engineSound = engineSound,
	}
	CarController.Active = true
	CarController.Chassis = chassis
	CarController.DriftScore = 0
end

local function hookCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Seated:Connect(function(isSeated, seatPart)
		if isSeated and seatPart and seatPart.Name == "DriverSeat" and seatPart:IsA("Seat") then
			activate(seatPart)
		else
			deactivate()
		end
	end)
end

-- ============================ SIMULATION ============================

local function resetCar(state: CarState)
	local position = state.chassis.Position
	local look = state.chassis.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = flat.Magnitude > 0.05 and flat.Unit or Vector3.new(0, 0, -1)
	state.model:PivotTo(CFrame.lookAt(position + Vector3.new(0, 5, 0), position + Vector3.new(0, 5, 0) + flat))
	state.chassis.AssemblyLinearVelocity = Vector3.zero
	state.chassis.AssemblyAngularVelocity = Vector3.zero
end

local function step(state: CarState, dt: number)
	local chassis = state.chassis
	if not chassis.Parent then
		deactivate()
		return
	end

	local throttle, steerInput, handbrake = readInput()

	local cf = chassis.CFrame
	local up = cf.UpVector
	local forward = cf.LookVector
	local velocity = chassis.AssemblyLinearVelocity
	local mass = chassis.AssemblyMass
	local forwardSpeed = velocity:Dot(forward)
	local planarSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	-- Speed-sensitive steering, smoothed toward the target angle.
	-- Positive steerInput (D) should yaw the car clockwise from above,
	-- which is a rotation by a *negative* angle around +Y.
	local steerLimit = MAX_STEER / (1 + planarSpeed / 65)
	local targetSteer = -steerInput * steerLimit
	local steerBlend = 1 - math.exp(-10 * dt)
	state.steer += (targetSteer - state.steer) * steerBlend

	-- Suspension constants (per wheel): sag ~35% of ride length at rest
	local perWheelLoad = mass * workspace.Gravity / 4
	local springK = perWheelLoad / (state.ride * 0.35)
	local damperC = 2 * math.sqrt(springK * mass / 4) * 0.55

	local rayLength = state.ride + state.wheelRadius
	local groundedCount = 0
	local poweredGrounded: { { dir: Vector3, pos: Vector3 } } = {}

	for _, wheel in state.wheels do
		local origin = wheel.attachment.WorldPosition
		local result = workspace:Raycast(origin, -up * rayLength, state.rayParams)

		if result then
			groundedCount += 1
			local dist = (result.Position - origin).Magnitude
			local compression = rayLength - dist
			wheel.compression = compression

			-- Spring + damper along the chassis up axis
			local pointVelocity = chassis:GetVelocityAtPosition(origin)
			local springForce = springK * compression - damperC * pointVelocity:Dot(up)
			springForce = math.clamp(springForce, 0, perWheelLoad * 5)
			chassis:ApplyImpulseAtPosition(up * springForce * dt, origin)

			-- Tire heading (front wheels rotate with steering)
			local wheelForward = forward
			if wheel.front and math.abs(state.steer) > 0.001 then
				wheelForward = CFrame.fromAxisAngle(up, state.steer) * forward
			end
			-- forward x up = right (LookVector x UpVector = RightVector)
			local wheelRight = wheelForward:Cross(up).Unit

			-- Lateral grip: cancel a fraction of sideways velocity each frame
			local lateralVelocity = pointVelocity:Dot(wheelRight)
			local gripHere = state.grip
			if handbrake and not wheel.front then
				gripHere *= 0.32
			end
			local cancel = 1 - math.exp(-gripHere * 5.5 * dt)
			chassis:ApplyImpulseAtPosition(wheelRight * (-lateralVelocity * cancel * mass / 4), origin)

			-- Collect powered wheels for drive force
			local powered = state.drive == "AWD" or not wheel.front
			if powered then
				table.insert(poweredGrounded, { dir = wheelForward, pos = origin })
			end

			-- Rolling resistance
			local rollVelocity = pointVelocity:Dot(wheelForward)
			chassis:ApplyImpulseAtPosition(wheelForward * (-rollVelocity * 0.01 * mass * dt), origin)
		else
			wheel.compression = 0
		end

		-- Visual wheel pose: steer + spin + suspension travel
		wheel.spin += (forwardSpeed / state.wheelRadius) * dt
		if wheel.spin > math.pi * 2 then
			wheel.spin -= math.pi * 2
		elseif wheel.spin < -math.pi * 2 then
			wheel.spin += math.pi * 2
		end
		local lift = wheel.compression > 0 and (wheel.compression - state.wheelRadius) or 0
		local visualOffset = wheel.baseOffset + Vector3.new(0, math.clamp(lift, -0.4, state.ride * 0.6), 0)
		local yaw = wheel.front and state.steer or 0
		wheel.weld.C0 = CFrame.new(visualOffset)
			* CFrame.Angles(0, yaw, 0)
			* CFrame.Angles(wheel.spin, 0, 0)
			* CFrame.Angles(0, 0, math.rad(90))
	end

	-- Drive / brake forces
	if #poweredGrounded > 0 and throttle ~= 0 then
		local braking = (throttle > 0 and forwardSpeed < -2) or (throttle < 0 and forwardSpeed > 2)
		if braking then
			local brakeForce = -math.sign(forwardSpeed) * state.brake * mass
			for _, contact in poweredGrounded do
				chassis:ApplyImpulseAtPosition(
					contact.dir * (brakeForce / #poweredGrounded) * dt, contact.pos)
			end
		else
			local falloff
			if throttle > 0 then
				falloff = math.clamp(1 - forwardSpeed / state.topSpeed, 0, 1)
			else
				falloff = math.clamp(1 - (-forwardSpeed) / REVERSE_TOP_SPEED, 0, 1) * 0.5
			end
			local driveForce = throttle * state.power * mass * falloff
			for _, contact in poweredGrounded do
				chassis:ApplyImpulseAtPosition(
					contact.dir * (driveForce / #poweredGrounded) * dt, contact.pos)
			end
		end
	end

	-- Handbrake also scrubs speed
	if handbrake and groundedCount > 0 and planarSpeed > 1 then
		chassis:ApplyImpulse(-velocity.Unit * mass * 18 * dt)
	end

	-- Aerodynamic drag + downforce
	chassis:ApplyImpulse(-velocity * mass * 0.045 * dt)
	if groundedCount >= 3 then
		chassis:ApplyImpulse(-up * planarSpeed * mass * 0.012 * dt)
	end

	-- Mid-air stabilisation so jumps don't turn into barrel rolls
	if groundedCount == 0 then
		local angular = chassis.AssemblyAngularVelocity
		chassis:ApplyAngularImpulse(-angular * mass * 1.5 * dt)
	end

	-- ============================ TELEMETRY ============================
	CarController.SpeedMph = planarSpeed * GameConfig.MphPerStudsPerSecond
	CarController.SpeedFraction = math.clamp(planarSpeed / state.topSpeed, 0, 1)

	local speedFrac = math.clamp(math.abs(forwardSpeed) / state.topSpeed, 0, 0.999)
	local gearFloat = speedFrac * GEARS
	CarController.Gear = math.clamp(math.floor(gearFloat) + 1, 1, GEARS)
	local inGear = gearFloat - math.floor(gearFloat)
	CarController.Rpm = 0.18 + inGear * 0.82

	if state.engineSound then
		state.engineSound.PlaybackSpeed = 0.7 + CarController.Rpm * 1.1
		state.engineSound.Volume = 0.3 + math.abs(throttle) * 0.35
	end

	-- Drift detection & style points
	local lateralSpeed = math.abs(velocity:Dot(cf.RightVector))
	local drifting = groundedCount > 0 and planarSpeed > 24 and lateralSpeed > 11
	CarController.Drifting = drifting
	if drifting then
		CarController.DriftScore += lateralSpeed * dt * 2.5
	elseif CarController.DriftScore > 0 and planarSpeed < 8 then
		CarController.DriftScore = 0
	end
end

-- ============================ START ============================

function CarController.Start()
	if player.Character then
		task.spawn(hookCharacter, player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R and current then
			resetCar(current :: CarState)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local state = current
		if state then
			step(state, math.min(dt, 1 / 20))
		end
	end)
end

return CarController

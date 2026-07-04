--!strict
-- Forza-style chase camera: sits behind the car, leans into the direction of
-- travel, widens FOV with speed, and hands control back to Roblox's default
-- camera when the player gets out.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CarController = require(script.Parent.CarController)

local ChaseCamera = {}

local player = Players.LocalPlayer

local BASE_FOV = 70
local MAX_FOV_BOOST = 16
local DISTANCE = 24
local HEIGHT = 8

local wasActive = false
local smoothedPosition: Vector3? = nil
local smoothedLook: Vector3? = nil

local function restoreDefault(camera: Camera)
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = BASE_FOV
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	smoothedPosition = nil
	smoothedLook = nil
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local chassis = CarController.Chassis
	if not CarController.Active or not chassis or not chassis.Parent then
		if wasActive then
			wasActive = false
			restoreDefault(camera)
		end
		return
	end
	wasActive = true
	camera.CameraType = Enum.CameraType.Scriptable

	local velocity = chassis.AssemblyLinearVelocity
	local planarVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local look = chassis.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	flatLook = flatLook.Magnitude > 0.05 and flatLook.Unit or Vector3.new(0, 0, -1)

	-- Follow direction blends from the car's heading (parked) into the
	-- direction of travel (moving), which makes drifts look great.
	local followDir = flatLook
	if planarVelocity.Magnitude > 14 then
		local travel = planarVelocity.Unit
		if travel:Dot(flatLook) > -0.2 then -- ignore reversing
			local blend = math.clamp((planarVelocity.Magnitude - 14) / 40, 0, 0.65)
			followDir = (flatLook:Lerp(travel, blend)).Unit
		end
	end

	local speedFrac = CarController.SpeedFraction
	local targetPosition = chassis.Position - followDir * (DISTANCE + speedFrac * 6)
		+ Vector3.new(0, HEIGHT + speedFrac * 2, 0)
	local targetLook = chassis.Position + Vector3.new(0, 2.5, 0) + followDir * 8

	local alpha = 1 - math.exp(-dt * 7)
	smoothedPosition = smoothedPosition and smoothedPosition:Lerp(targetPosition, alpha) or targetPosition
	smoothedLook = smoothedLook and smoothedLook:Lerp(targetLook, alpha * 1.4) or targetLook

	camera.CFrame = CFrame.lookAt(smoothedPosition :: Vector3, smoothedLook :: Vector3)
	camera.FieldOfView = BASE_FOV + speedFrac * MAX_FOV_BOOST
end

function ChaseCamera.Start()
	RunService.RenderStepped:Connect(update)
end

return ChaseCamera

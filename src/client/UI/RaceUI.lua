--!strict
-- Race presentation: countdown, timer, checkpoint gates rendered locally,
-- and a results card. Input is locked during the countdown.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(script.Parent.Theme)
local CarController = require(script.Parent.Parent.CarController)
local Notifications = require(script.Parent.Notifications)

local RaceUI = {}

local player = Players.LocalPlayer
local countdownLabel: TextLabel
local timerPanel: Frame
local timerLabel: TextLabel
local checkpointLabel: TextLabel
local routeLabel: TextLabel

local gatesFolder: Folder? = nil
local gates: { Model } = {}
local beacon: Part? = nil
local racing = false
local raceStart = 0
local checkpoints: { Vector3 } = {}

local function clearGates()
	if gatesFolder then
		gatesFolder:Destroy()
		gatesFolder = nil
	end
	gates = {}
	beacon = nil
end

local function setGateColor(gate: Model, active: boolean)
	for _, part in gate:GetChildren() do
		if part:IsA("BasePart") then
			part.Color = active and Theme.Colors.Accent or Theme.Colors.Accent2
			part.Transparency = active and 0 or 0.55
		end
	end
end

local function buildGates()
	clearGates()
	gatesFolder = Instance.new("Folder")
	gatesFolder.Name = "RaceGates"

	local previous = checkpoints[1] - (checkpoints[2] - checkpoints[1])
	for i, pos in checkpoints do
		local direction = (pos - previous)
		direction = Vector3.new(direction.X, 0, direction.Z)
		direction = direction.Magnitude > 0.1 and direction.Unit or Vector3.new(0, 0, -1)
		local side = direction:Cross(Vector3.yAxis)

		local gate = Instance.new("Model")
		for _, s in { -1, 1 } do
			local pillar = Instance.new("Part")
			pillar.Anchored = true
			pillar.CanCollide = false
			pillar.CanQuery = false
			pillar.Material = Enum.Material.Neon
			pillar.Size = Vector3.new(1.6, 16, 1.6)
			pillar.CFrame = CFrame.new(pos + side * s * 17 + Vector3.new(0, 8, 0))
			pillar.Parent = gate
		end
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.Material = Enum.Material.Neon
		beam.Size = Vector3.new(34, 1.4, 1.4)
		beam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 16, 0), pos + Vector3.new(0, 16, 0) + direction)
			* CFrame.Angles(0, math.rad(90), 0)
		beam.Parent = gate

		setGateColor(gate, i == 1)
		gate.Parent = gatesFolder
		table.insert(gates, gate)
		previous = pos
	end

	-- Tall light column over the next checkpoint
	beacon = Instance.new("Part")
	local b = beacon :: Part
	b.Anchored = true
	b.CanCollide = false
	b.CanQuery = false
	b.Material = Enum.Material.Neon
	b.Color = Theme.Colors.Accent
	b.Transparency = 0.55
	b.Size = Vector3.new(3, 220, 3)
	b.CFrame = CFrame.new(checkpoints[1] + Vector3.new(0, 110, 0))
	b.Parent = gatesFolder

	(gatesFolder :: Folder).Parent = workspace
end

local function onCheckpoint(index: number, total: number)
	local gate = gates[index]
	if gate then
		gate:Destroy()
	end
	local nextGate = gates[index + 1]
	if nextGate then
		setGateColor(nextGate, true)
	end
	if beacon and checkpoints[index + 1] then
		(beacon :: Part).CFrame = CFrame.new(checkpoints[index + 1] + Vector3.new(0, 110, 0))
	end
	checkpointLabel.Text = ("CHECKPOINT %d / %d"):format(index, total)
end

local function endRace()
	racing = false
	CarController.InputLocked = false
	timerPanel.Visible = false
	clearGates()
end

local function showResults(payload: any)
	local panel = Theme.Panel(countdownLabel.Parent :: Instance, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.new(0, 360, 0, 170),
	})
	Theme.Stroke(panel, payload.beatPar and Theme.Colors.Gold or Theme.Colors.Accent2, 2, 0.2)
	Theme.Label(panel, {
		Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.FontHeavy, TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = payload.beatPar and Theme.Colors.Gold or Theme.Colors.Text,
		Text = payload.beatPar and "PAR BEATEN!" or "RACE COMPLETE",
	})
	Theme.Label(panel, {
		Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.FontBold, TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = ("TIME  %.2fs   (PAR %ds)"):format(payload.time, payload.parTime),
	})
	Theme.Label(panel, {
		Position = UDim2.new(0, 0, 0, 96), Size = UDim2.new(1, 0, 0, 34),
		Font = Theme.FontHeavy, TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.Colors.Good,
		Text = "+" .. Theme.FormatCredits(payload.reward),
	})
	task.delay(6, function()
		panel:Destroy()
	end)
end

local function handleUpdate(payload: any)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "prep" then
		checkpoints = payload.checkpoints
		CarController.InputLocked = true
		buildGates()
		routeLabel.Text = string.upper(payload.routeName)
		checkpointLabel.Text = ("CHECKPOINT 0 / %d"):format(#checkpoints)
		timerLabel.Text = "0.00"
		timerPanel.Visible = true
	elseif payload.type == "countdown" then
		countdownLabel.Text = tostring(payload.n)
		countdownLabel.Visible = true
	elseif payload.type == "go" then
		countdownLabel.Text = "GO!"
		racing = true
		raceStart = os.clock()
		CarController.InputLocked = false
		task.delay(0.8, function()
			countdownLabel.Visible = false
		end)
	elseif payload.type == "checkpoint" then
		onCheckpoint(payload.index, payload.total)
	elseif payload.type == "finish" then
		endRace()
		showResults(payload)
	elseif payload.type == "dnf" then
		endRace()
		Notifications.Push("Race over: " .. tostring(payload.reason), "error")
	end
end

function RaceUI.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ForzaBloxRace"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.Parent = player:WaitForChild("PlayerGui")

	countdownLabel = Theme.Label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.35),
		Size = UDim2.new(0, 300, 0, 120),
		Font = Theme.FontHeavy, TextSize = 96,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.Colors.Accent,
		TextStrokeTransparency = 0.5,
		Text = "3",
	})
	countdownLabel.Visible = false

	timerPanel = Theme.Panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.new(0, 320, 0, 74),
		BackgroundTransparency = 0.2,
	})
	timerPanel.Visible = false
	routeLabel = Theme.Label(timerPanel, {
		Position = UDim2.new(0, 0, 0, 6), Size = UDim2.new(1, 0, 0, 18),
		Font = Theme.FontBold, TextSize = 14,
		TextColor3 = Theme.Colors.Accent2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "",
	})
	timerLabel = Theme.Label(timerPanel, {
		Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.FontHeavy, TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "0.00",
	})
	checkpointLabel = Theme.Label(timerPanel, {
		Position = UDim2.new(0, 0, 1, -20), Size = UDim2.new(1, 0, 0, 16),
		Font = Theme.FontBold, TextSize = 13,
		TextColor3 = Theme.Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "",
	})

	RunService.RenderStepped:Connect(function()
		if racing then
			timerLabel.Text = ("%.2f"):format(os.clock() - raceStart)
		end
	end)

	local raceUpdate = Remotes.Get("RaceUpdate") :: RemoteEvent
	raceUpdate.OnClientEvent:Connect(handleUpdate)
end

return RaceUI

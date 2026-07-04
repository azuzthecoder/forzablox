--!strict
-- In-game HUD: Forza-style speedo (speed, gear, RPM tick arc), drift score
-- popup, credits readout and a live minimap of the island.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared:WaitForChild("MapLayout"))
local Theme = require(script.Parent.Theme)
local ClientState = require(script.Parent.Parent.ClientState)
local CarController = require(script.Parent.Parent.CarController)

local HUD = {}

local player = Players.LocalPlayer

local RPM_TICKS = 14

local speedLabel: TextLabel
local gearLabel: TextLabel
local driftLabel: TextLabel
local creditsLabel: TextLabel
local speedoFrame: Frame
local rpmTicks: { Frame } = {}
local playerArrow: Frame
local minimapFrame: Frame
local minimapScale = 1

-- ============================ SPEEDOMETER ============================

local function buildSpeedo(gui: ScreenGui)
	speedoFrame = Instance.new("Frame")
	speedoFrame.Size = UDim2.new(0, 190, 0, 190)
	speedoFrame.Position = UDim2.new(1, -215, 1, -215)
	speedoFrame.BackgroundColor3 = Theme.Colors.Background
	speedoFrame.BackgroundTransparency = 0.25
	speedoFrame.BorderSizePixel = 0
	speedoFrame.Visible = false
	Theme.Corner(speedoFrame, 95)
	Theme.Stroke(speedoFrame, Theme.Colors.Accent, 2, 0.35)
	speedoFrame.Parent = gui

	-- RPM tick arc: each tick lives at the top of an invisible rotated holder
	for i = 1, RPM_TICKS do
		local holder = Instance.new("Frame")
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.Rotation = -120 + (i - 1) * (240 / (RPM_TICKS - 1))
		holder.Parent = speedoFrame

		local tick = Instance.new("Frame")
		tick.AnchorPoint = Vector2.new(0.5, 0)
		tick.Size = UDim2.new(0, 5, 0, 14)
		tick.Position = UDim2.new(0.5, 0, 0, 6)
		tick.BackgroundColor3 = Theme.Colors.PanelLight
		tick.BorderSizePixel = 0
		Theme.Corner(tick, 2)
		tick.Parent = holder
		table.insert(rpmTicks, tick)
	end

	speedLabel = Theme.Label(speedoFrame, {
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 0.5, -34),
		Font = Theme.FontHeavy,
		TextSize = 48,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "0",
	})

	Theme.Label(speedoFrame, {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0.5, 18),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "MPH",
	})

	gearLabel = Theme.Label(speedoFrame, {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0.5, 38),
		Font = Theme.FontHeavy,
		TextSize = 22,
		TextColor3 = Theme.Colors.Accent2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "1",
	})

	driftLabel = Theme.Label(gui, {
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.new(0, 220, 0, 30),
		Position = UDim2.new(1, -215, 1, -225),
		Font = Theme.FontHeavy,
		TextSize = 22,
		TextColor3 = Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeTransparency = 0.6,
		Text = "",
	})
end

-- ============================ MINIMAP ============================

local function mapDot(parent: Instance, worldX: number, worldZ: number, sizePx: number, color: Color3): Frame
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.new(0, sizePx, 0, sizePx)
	dot.Position = UDim2.new(0.5, worldX * minimapScale, 0.5, worldZ * minimapScale)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	Theme.Corner(dot, math.ceil(sizePx / 2))
	dot.Parent = parent
	return dot
end

local function buildMinimap(gui: ScreenGui)
	local mapSize = 190
	minimapScale = (mapSize / 2) * 0.72 / Layout.RingRadius

	minimapFrame = Instance.new("Frame")
	minimapFrame.Size = UDim2.new(0, mapSize, 0, mapSize)
	minimapFrame.Position = UDim2.new(0, 25, 1, -215)
	minimapFrame.BackgroundColor3 = Theme.Colors.Background
	minimapFrame.BackgroundTransparency = 0.3
	minimapFrame.BorderSizePixel = 0
	minimapFrame.ClipsDescendants = true
	Theme.Corner(minimapFrame, math.ceil(mapSize / 2))
	Theme.Stroke(minimapFrame, Theme.Colors.Accent2, 2, 0.4)
	minimapFrame.Parent = gui

	-- Ring highway
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	local ringPx = Layout.RingRadius * 2 * minimapScale
	ring.Size = UDim2.new(0, ringPx, 0, ringPx)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.BackgroundTransparency = 1
	Theme.Corner(ring, math.ceil(ringPx / 2))
	Theme.Stroke(ring, Color3.fromRGB(120, 124, 140), 3, 0.15)
	ring.Parent = minimapFrame

	-- Cross roads
	for _, vertical in { true, false } do
		local road = Instance.new("Frame")
		road.AnchorPoint = Vector2.new(0.5, 0.5)
		road.Size = vertical and UDim2.new(0, 3, 0, ringPx) or UDim2.new(0, ringPx, 0, 3)
		road.Position = UDim2.fromScale(0.5, 0.5)
		road.BackgroundColor3 = Color3.fromRGB(120, 124, 140)
		road.BackgroundTransparency = 0.15
		road.BorderSizePixel = 0
		road.Parent = minimapFrame
	end

	-- Landmarks: festival hub, dealership, lake
	mapDot(minimapFrame, 0, 0, 9, Theme.Colors.Accent)
	mapDot(minimapFrame, Layout.DealershipPosition.X, Layout.DealershipPosition.Z, 7, Theme.Colors.Accent2)
	local lake = mapDot(minimapFrame, Layout.LakeCenter.X, Layout.LakeCenter.Z,
		math.floor(Layout.LakeRadius * 2 * minimapScale), Color3.fromRGB(52, 120, 190))
	lake.BackgroundTransparency = 0.35

	-- Player arrow (drawn last, on top)
	playerArrow = Instance.new("Frame")
	playerArrow.AnchorPoint = Vector2.new(0.5, 0.5)
	playerArrow.Size = UDim2.new(0, 16, 0, 16)
	playerArrow.Position = UDim2.fromScale(0.5, 0.5)
	playerArrow.BackgroundTransparency = 1
	playerArrow.Parent = minimapFrame

	local arrowText = Instance.new("TextLabel")
	arrowText.Size = UDim2.fromScale(1, 1)
	arrowText.BackgroundTransparency = 1
	arrowText.Font = Theme.FontHeavy
	arrowText.TextSize = 15
	arrowText.TextColor3 = Theme.Colors.Gold
	arrowText.TextStrokeTransparency = 0.4
	arrowText.Text = "▲"
	arrowText.Parent = playerArrow
end

-- ============================ TOP BAR ============================

local function buildTopBar(gui: ScreenGui)
	local panel = Theme.Panel(gui, {
		Size = UDim2.new(0, 190, 0, 40),
		Position = UDim2.new(1, -215, 0, 20),
		BackgroundTransparency = 0.2,
	})
	Theme.Stroke(panel, Theme.Colors.Gold, 1.5, 0.5)

	creditsLabel = Theme.Label(panel, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Font = Theme.FontHeavy,
		TextSize = 17,
		TextColor3 = Theme.Colors.Gold,
		Text = "0 CR",
	})

	Theme.Label(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(0, 640, 0, 20),
		Position = UDim2.new(0.5, 0, 1, -8),
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.7,
		Text = "WASD drive  •  SPACE handbrake  •  R flip car  •  G garage  •  Race boards start events",
	})
end

-- ============================ UPDATE ============================

local function update()
	-- Credits
	creditsLabel.Text = Theme.FormatCredits(ClientState.Profile.credits)

	-- Speedo
	local active = CarController.Active
	speedoFrame.Visible = active
	if active then
		speedLabel.Text = tostring(math.floor(CarController.SpeedMph + 0.5))
		gearLabel.Text = tostring(CarController.Gear)

		local litCount = math.floor(CarController.Rpm * RPM_TICKS + 0.5)
		for i, tick in rpmTicks do
			if i <= litCount then
				tick.BackgroundColor3 = i > RPM_TICKS - 3 and Theme.Colors.Bad or Theme.Colors.Accent2
			else
				tick.BackgroundColor3 = Theme.Colors.PanelLight
			end
		end

		if CarController.Drifting or CarController.DriftScore > 0 then
			driftLabel.Text = CarController.DriftScore > 1
				and ("DRIFT +" .. tostring(math.floor(CarController.DriftScore))) or ""
			driftLabel.TextTransparency = CarController.Drifting and 0 or 0.4
		else
			driftLabel.Text = ""
		end
	else
		driftLabel.Text = ""
	end

	-- Minimap player arrow
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tracked: BasePart? = CarController.Chassis or root
	if tracked then
		local pos = tracked.Position
		local px = math.clamp(pos.X * minimapScale, -86, 86)
		local py = math.clamp(pos.Z * minimapScale, -86, 86)
		playerArrow.Position = UDim2.new(0.5, px, 0.5, py)
		local look = tracked.CFrame.LookVector
		playerArrow.Rotation = math.deg(math.atan2(look.X, look.Z)) - 180
	end
end

-- ============================ START ============================

function HUD.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ForzaBloxHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	buildSpeedo(gui)
	buildMinimap(gui)
	buildTopBar(gui)

	RunService.RenderStepped:Connect(update)
end

return HUD

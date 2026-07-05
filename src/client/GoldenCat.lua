--!strict
-- Stage 4: the Golden Cat. When the server offers one, a shimmering cat
-- drifts across the screen; clicking it grants a temporary x7 boost to all
-- treat gains. A banner with a countdown shows while the boost is active.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GoldenCat = {}

local player = Players.LocalPlayer
local C = Config.Colors
local rng = Random.new()

local GOLD = Color3.fromRGB(255, 200, 90)
local GOLD_DARK = Color3.fromRGB(200, 140, 40)

local gui: ScreenGui
local banner: TextLabel
local boostEndsAt = 0
local activeCat: TextButton? = nil

local function removeCat()
	if activeCat then
		activeCat:Destroy()
		activeCat = nil
	end
end

local function spawnCat(window: number, onClicked: () -> ())
	removeCat()

	local cat = Instance.new("TextButton")
	activeCat = cat
	cat.Size = UDim2.fromOffset(90, 90)
	cat.BackgroundColor3 = GOLD
	cat.Text = "😺"
	cat.TextSize = 46
	cat.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = cat
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD_DARK
	stroke.Thickness = 3
	stroke.Parent = cat

	local sparkle = Instance.new("TextLabel")
	sparkle.BackgroundTransparency = 1
	sparkle.Size = UDim2.fromScale(1, 0.5)
	sparkle.Position = UDim2.fromScale(0, -0.35)
	sparkle.Text = "✨"
	sparkle.TextSize = 24
	sparkle.Parent = cat

	-- Drift from one side of the screen to the other at a random height
	local leftToRight = rng:NextNumber() > 0.5
	local y = rng:NextNumber(0.2, 0.7)
	cat.Position = UDim2.new(leftToRight and -0.1 or 1.1, 0, y, 0)
	cat.Parent = gui

	local drift = TweenService:Create(cat, TweenInfo.new(window, Enum.EasingStyle.Linear), {
		Position = UDim2.new(leftToRight and 1.1 or -0.1, 0, y + rng:NextNumber(-0.12, 0.12), 0),
	})
	drift.Completed:Connect(function()
		if activeCat == cat then
			removeCat()
		end
	end)
	drift:Play()

	-- Gentle shimmer wobble
	task.spawn(function()
		while cat.Parent do
			TweenService:Create(cat, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Rotation = 8 }):Play()
			task.wait(0.5)
			TweenService:Create(cat, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Rotation = -8 }):Play()
			task.wait(0.5)
		end
	end)

	cat.MouseButton1Click:Connect(function()
		-- Burst of sparkles where it was caught
		for _ = 1, 8 do
			local bit = Instance.new("TextLabel")
			bit.BackgroundTransparency = 1
			bit.Position = cat.Position
			bit.Size = UDim2.fromOffset(30, 30)
			bit.Text = "✨"
			bit.TextSize = 22
			bit.Parent = gui
			TweenService:Create(bit, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = cat.Position + UDim2.fromOffset(rng:NextInteger(-90, 90), rng:NextInteger(-90, 90)),
				TextTransparency = 1,
			}):Play()
			task.delay(0.75, function()
				bit:Destroy()
			end)
		end
		removeCat()
		onClicked()
	end)
end

function GoldenCat.Start()
	local offerEvent = ReplicatedStorage:WaitForChild("GoldenCatOffer") :: RemoteEvent
	local clickEvent = ReplicatedStorage:WaitForChild("GoldenCatClick") :: RemoteEvent
	local boostSync = ReplicatedStorage:WaitForChild("BoostSync") :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerGolden"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 40
	gui.Parent = player:WaitForChild("PlayerGui")

	banner = Instance.new("TextLabel")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 170)
	banner.Size = UDim2.new(0, 460, 0, 34)
	banner.BackgroundColor3 = GOLD
	banner.Font = Enum.Font.FredokaOne
	banner.TextSize = 20
	banner.TextColor3 = Color3.fromRGB(120, 75, 20)
	banner.Text = ""
	banner.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = banner
	banner.Parent = gui

	offerEvent.OnClientEvent:Connect(function(window)
		spawnCat(type(window) == "number" and window or 12, function()
			clickEvent:FireServer()
		end)
	end)

	boostSync.OnClientEvent:Connect(function(mult, duration)
		if type(mult) == "number" and type(duration) == "number" then
			boostEndsAt = os.clock() + duration
			banner.Visible = true
		end
	end)

	RunService.RenderStepped:Connect(function()
		if banner.Visible then
			local remaining = boostEndsAt - os.clock()
			if remaining <= 0 then
				banner.Visible = false
			else
				banner.Text = ("🌟 GOLDEN CAT!  x%d treats for %ds 🌟"):format(
					Config.GoldenCat.Multiplier, math.ceil(remaining))
			end
		end
	end)
end

return GoldenCat

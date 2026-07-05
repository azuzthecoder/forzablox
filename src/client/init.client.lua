--!strict
-- Cat Clicker client — Stage 1: big clickable cat, Treats counter,
-- floating "+1" popups and a meow per click. Bright pastel style.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local clickEvent = ReplicatedStorage:WaitForChild("ClickTreat") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = Config.Colors

local rng = Random.new()

-- ============================ HELPERS ============================

local function round(instance: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function circle(instance: Instance)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = instance
end

local function frame(parent: Instance, props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for key, value in props do
		(f :: any)[key] = value
	end
	f.Parent = parent
	return f
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = C.Text
	for key, value in props do
		(l :: any)[key] = value
	end
	l.Parent = parent
	return l
end

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	while true do
		local replaced
		s, replaced = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return s
end

-- ============================ SCREEN ============================

local gui = Instance.new("ScreenGui")
gui.Name = "CatClicker"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Soft cream backdrop covering the whole screen (it's a UI game!)
local backdrop = frame(gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Background,
})

-- A few decorative pastel bubbles
for _ = 1, 10 do
	local size = rng:NextInteger(40, 120)
	local bubble = frame(backdrop, {
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromScale(rng:NextNumber(0, 0.95), rng:NextNumber(0, 0.95)),
		BackgroundColor3 = C.Pink,
		BackgroundTransparency = 0.88,
	})
	circle(bubble)
end

-- Title + Treats counter
label(backdrop, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0, 600, 0, 34),
	TextSize = 30,
	TextColor3 = C.PinkDark,
	Text = "🐾 Cat Clicker 🐾",
})

local treatsLabel = label(backdrop, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 50),
	Size = UDim2.new(0, 700, 0, 64),
	TextSize = 56,
	Text = "0 Treats",
})
label(backdrop, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 116),
	Size = UDim2.new(0, 500, 0, 22),
	TextSize = 18,
	TextColor3 = C.TextSoft,
	Text = "click the cat!",
})

-- ============================ THE CAT ============================
-- Built entirely from rounded frames, so no image assets are needed.

local catButton = Instance.new("TextButton")
catButton.Name = "Cat"
catButton.AnchorPoint = Vector2.new(0.5, 0.5)
catButton.Position = UDim2.fromScale(0.5, 0.58)
catButton.Size = UDim2.fromOffset(300, 300)
catButton.BackgroundTransparency = 1
catButton.Text = ""
catButton.Parent = backdrop

local cat = frame(catButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
})

-- Soft shadow under the cat
local shadow = frame(cat, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 14),
	Size = UDim2.new(0.8, 0, 0, 30),
	BackgroundColor3 = C.PanelShadow,
	BackgroundTransparency = 0.5,
})
circle(shadow)

-- Ears (rotated rounded squares behind the head)
for _, side in { -1, 1 } do
	local ear = frame(cat, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + side * 0.28, 0.13),
		Size = UDim2.fromScale(0.3, 0.3),
		Rotation = 45,
		BackgroundColor3 = C.CatBody,
	})
	round(ear, 18)
	local inner = frame(ear, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		BackgroundColor3 = C.CatInnerEar,
	})
	round(inner, 12)
end

-- Head
local head = frame(cat, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.55),
	Size = UDim2.fromScale(0.92, 0.82),
	BackgroundColor3 = C.CatBody,
})
circle(head)

-- Eyes
for _, side in { -1, 1 } do
	local eye = frame(head, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + side * 0.19, 0.42),
		Size = UDim2.fromOffset(26, 34),
		BackgroundColor3 = C.Text,
	})
	circle(eye)
	local shine = frame(eye, {
		Position = UDim2.fromScale(0.55, 0.12),
		Size = UDim2.fromScale(0.32, 0.28),
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	circle(shine)
end

-- Blush
for _, side in { -1, 1 } do
	local blush = frame(head, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + side * 0.32, 0.62),
		Size = UDim2.fromOffset(34, 20),
		BackgroundColor3 = C.Pink,
		BackgroundTransparency = 0.35,
	})
	circle(blush)
end

-- Nose + mouth
local nose = frame(head, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.58),
	Size = UDim2.fromOffset(20, 14),
	BackgroundColor3 = C.PinkDark,
})
circle(nose)
label(head, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.72),
	Size = UDim2.fromOffset(60, 30),
	TextSize = 24,
	TextColor3 = C.Text,
	Text = "ω",
})

-- Whiskers
for _, side in { -1, 1 } do
	for i = -1, 1 do
		local whisker = frame(head, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + side * 0.44, 0.58 + i * 0.07),
			Size = UDim2.fromOffset(52, 3),
			Rotation = side * i * -8,
			BackgroundColor3 = C.TextSoft,
		})
		circle(whisker)
	end
end

-- ============================ SOUND ============================

local meow = Instance.new("Sound")
meow.Name = "Meow"
meow.SoundId = Config.MeowSoundId ~= "" and Config.MeowSoundId or Config.FallbackClickSound
meow.Volume = 0.6
meow.Parent = gui

-- ============================ CLICKING ============================

local squishInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local unsquishInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function popup(amount: number, x: number, y: number)
	local pop = label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x + rng:NextInteger(-14, 14), y + rng:NextInteger(-6, 6)),
		Size = UDim2.fromOffset(120, 36),
		TextSize = 28,
		TextColor3 = C.Accent,
		TextStrokeColor3 = C.Text,
		TextStrokeTransparency = 0.75,
		Text = "+" .. formatNumber(amount),
	})
	TweenService:Create(pop, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = pop.Position - UDim2.fromOffset(0, 70),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(0.85, function()
		pop:Destroy()
	end)
end

local lastClickX, lastClickY = 0, 0

catButton.MouseButton1Down:Connect(function(x, y)
	lastClickX, lastClickY = x, y
	clickEvent:FireServer()

	meow.PlaybackSpeed = rng:NextNumber(0.92, 1.12)
	meow:Play()

	TweenService:Create(cat, squishInfo, { Size = UDim2.fromScale(0.9, 0.86) }):Play()
	task.delay(0.08, function()
		TweenService:Create(cat, unsquishInfo, { Size = UDim2.fromScale(1, 1) }):Play()
	end)
end)

-- Popup shows the server-confirmed amount (includes click upgrades)
clickEvent.OnClientEvent:Connect(function(gained)
	if type(gained) == "number" then
		popup(gained, lastClickX, lastClickY)
	end
end)

-- ============================ COUNTER ============================

local function watchTreats()
	local stats = player:WaitForChild("leaderstats")
	local treats = stats:WaitForChild("Treats") :: NumberValue
	local function update()
		treatsLabel.Text = formatNumber(treats.Value) .. " Treats"
	end
	treats.Changed:Connect(update)
	update()
end
task.spawn(watchTreats)

-- Stage 2: upgrade shop sidebar
local Shop = require(script.Shop)
Shop.Start()

-- Stage 4: golden cat bonus event
local GoldenCat = require(script.GoldenCat)
GoldenCat.Start()

print("[CatClicker] Client ready — stages 1-4")

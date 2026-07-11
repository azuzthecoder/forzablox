--!strict
-- Cat Clicker client: the big chonky orange tabby, Treats counter,
-- floating "+X" popups, click sound, ambient background life.

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

local formatNumber = Config.FormatNumber

-- ============================ SCREEN ============================

local gui = Instance.new("ScreenGui")
gui.Name = "CatClicker"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local backdrop = frame(gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Background,
})

-- Decorative pastel bubbles
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

-- Ambient drifting treats floating up the screen
task.spawn(function()
	local drifts = { "🐾", "🍪", "🧶", "🐟" }
	while true do
		task.wait(rng:NextNumber(1.8, 3.2))
		local drift = label(backdrop, {
			Position = UDim2.new(rng:NextNumber(0.05, 0.9), 0, 1.05, 0),
			Size = UDim2.fromOffset(40, 40),
			TextSize = rng:NextInteger(18, 34),
			TextTransparency = 0.72,
			Text = drifts[rng:NextInteger(1, #drifts)],
		})
		local lifetime = rng:NextNumber(11, 16)
		TweenService:Create(drift, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {
			Position = drift.Position - UDim2.fromScale(0, 1.15),
			TextTransparency = 1,
			Rotation = rng:NextInteger(-40, 40),
		}):Play()
		task.delay(lifetime, function()
			drift:Destroy()
		end)
	end
end)

-- Title + Treats counter (bubble style)
local titleLabel = label(backdrop, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0, 600, 0, 34),
	TextSize = 32,
	TextColor3 = C.PinkDark,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "🐾 Cat Clicker 🐾",
})
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.new(1, 1, 1)
titleStroke.Thickness = 2.5
titleStroke.Parent = titleLabel

local treatsLabel = label(backdrop, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 50),
	Size = UDim2.new(0, 700, 0, 64),
	TextSize = 56,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "0 Treats",
})
local coinsLabel = label(backdrop, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 138),
	Size = UDim2.new(0, 400, 0, 24),
	TextSize = 18,
	TextColor3 = C.Accent,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "🪙 0 Paw Coins",
})
local function updateCoins()
	coinsLabel.Text = "🪙 " .. formatNumber((player:GetAttribute("PawCoins") :: number?) or 0) .. " Paw Coins"
end
player:GetAttributeChangedSignal("PawCoins"):Connect(updateCoins)
updateCoins()

-- ============================ THE CHONKY CAT ============================
-- A very round orange tabby, built entirely from rounded frames.

local catButton = Instance.new("TextButton")
catButton.Name = "Cat"
catButton.AnchorPoint = Vector2.new(0.5, 0.5)
catButton.Position = UDim2.fromScale(0.5, 0.6)
-- Scales with the screen so banners above never overlap the cat
catButton.Size = UDim2.fromScale(0.42, 0.55)
local catAspect = Instance.new("UIAspectRatioConstraint")
catAspect.AspectRatio = 0.92
catAspect.AspectType = Enum.AspectType.FitWithinMaxSize
catAspect.Parent = catButton
catButton.BackgroundTransparency = 1
catButton.Text = ""
catButton.Parent = backdrop

local cat = frame(catButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
})

-- Soft shadow
local shadow = frame(cat, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 12),
	Size = UDim2.new(0.85, 0, 0, 34),
	BackgroundColor3 = C.PanelShadow,
	BackgroundTransparency = 0.45,
})
circle(shadow)

-- Ears (behind the head)
for _, side in { -1, 1 } do
	local ear = frame(cat, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + side * 0.21, 0.075),
		Size = UDim2.fromOffset(74, 74),
		Rotation = 45,
		BackgroundColor3 = C.CatBody,
	})
	round(ear, 16)
	local inner = frame(ear, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.52, 0.52),
		BackgroundColor3 = C.CatInnerEar,
	})
	round(inner, 10)
end

-- The BODY: big and round like the real chonker
local body = frame(cat, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -4),
	Size = UDim2.new(0.98, 0, 0.62, 0),
	BackgroundColor3 = C.CatBody,
})
round(body, 110)

-- Tabby stripes on the body sides
for _, side in { -1, 1 } do
	for i = 0, 2 do
		local stripe = frame(body, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + side * (0.42 - i * 0.035), 0.3 + i * 0.2),
			Size = UDim2.fromOffset(46, 13),
			Rotation = side * (18 - i * 8),
			BackgroundColor3 = C.CatStripe,
		})
		circle(stripe)
	end
end

-- Lighter belly fluff
local belly = frame(body, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(0.56, 0, 0.72, 0),
	BackgroundColor3 = C.CatBelly,
})
round(belly, 90)

-- Front paws resting on the belly
for _, side in { -1, 1 } do
	local paw = frame(cat, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5 + side * 0.14, 0, 1, -8),
		Size = UDim2.fromOffset(56, 40),
		BackgroundColor3 = C.CatBody,
	})
	round(paw, 20)
	frame(paw, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.7, 0, 0, 8),
		BackgroundColor3 = C.CatStripe,
		BackgroundTransparency = 0.55,
	})
end

-- The HEAD sits on top of (and slightly into) the body
local head = frame(cat, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(214, 176),
	BackgroundColor3 = C.CatBody,
})
round(head, 88)

-- Head stripes (classic tabby "M")
for i = -1, 1 do
	local stripe = frame(head, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5 + i * 0.16, 0, 0, 6),
		Size = UDim2.fromOffset(14, 34 - math.abs(i) * 10),
		BackgroundColor3 = C.CatStripe,
	})
	circle(stripe)
end

-- Eyes: wide-set, a little unimpressed (like the real one)
for _, side in { -1, 1 } do
	local eye = frame(head, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + side * 0.22, 0.46),
		Size = UDim2.fromOffset(24, 26),
		BackgroundColor3 = C.Text,
	})
	circle(eye)
	local shine = frame(eye, {
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.fromScale(0.3, 0.28),
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	circle(shine)
	-- sleepy upper eyelid
	frame(head, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + side * 0.22, 0.40),
		Size = UDim2.fromOffset(26, 8),
		BackgroundColor3 = C.CatBody,
	})
end

-- Muzzle, nose and mouth
local muzzle = frame(head, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.68),
	Size = UDim2.fromOffset(74, 48),
	BackgroundColor3 = C.CatBelly,
})
round(muzzle, 26)
local nose = frame(head, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.6),
	Size = UDim2.fromOffset(20, 13),
	BackgroundColor3 = C.CatInnerEar,
})
circle(nose)
label(head, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.74),
	Size = UDim2.fromOffset(60, 26),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "ω",
})

-- Long whiskers
for _, side in { -1, 1 } do
	for i = -1, 1 do
		local whisker = frame(head, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + side * 0.47, 0.62 + i * 0.07),
			Size = UDim2.fromOffset(66, 3),
			Rotation = side * i * -7,
			BackgroundColor3 = Color3.fromRGB(250, 245, 238),
		})
		circle(whisker)
	end
end

-- If a real cat picture is configured, use it INSTEAD of the drawn cat.
-- (Upload your image as a Decal and paste its id into Config.Images.MainCat)
if Config.Images.MainCat ~= "" then
	for _, child in cat:GetChildren() do
		(child :: any).Visible = false
	end
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1, 1)
	img.BackgroundTransparency = 1
	img.Image = Config.Images.MainCat
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = cat
end

-- Idle breathing (pauses briefly while being clicked)
local lastClick = 0
task.spawn(function()
	while true do
		if os.clock() - lastClick > 0.6 then
			TweenService:Create(cat, TweenInfo.new(1.1, Enum.EasingStyle.Sine), {
				Size = UDim2.fromScale(1.015, 1.03),
			}):Play()
			task.wait(1.1)
			TweenService:Create(cat, TweenInfo.new(1.1, Enum.EasingStyle.Sine), {
				Size = UDim2.fromScale(1, 1),
			}):Play()
			task.wait(1.1)
		else
			task.wait(0.3)
		end
	end
end)

-- ============================ SOUND ============================

-- Template sound; each click plays its own clone so rapid clicks all meow
-- instead of restarting one sound (which went silent while spam-clicking).
local meowTemplate = Instance.new("Sound")
meowTemplate.Name = "Meow"
meowTemplate.SoundId = Config.MeowSoundId ~= "" and Config.MeowSoundId or Config.FallbackClickSound
meowTemplate.Volume = Config.ClickVolume
meowTemplate.Parent = gui

local function playMeow()
	local sound = meowTemplate:Clone()
	sound.PlaybackSpeed = rng:NextNumber(0.92, 1.12)
	sound.Parent = gui
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

-- ============================ CLICKING ============================

local squishInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local unsquishInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function popup(amount: number, x: number, y: number)
	local pop = label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x + rng:NextInteger(-14, 14), y + rng:NextInteger(-6, 6)),
		Size = UDim2.fromOffset(140, 36),
		TextSize = 28,
		TextColor3 = C.Accent,
		TextStrokeColor3 = C.Text,
		TextStrokeTransparency = 0.75,
		TextXAlignment = Enum.TextXAlignment.Center,
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

-- Popups appear instantly using the last server-confirmed gain, so fast
-- clicking always feels responsive; the server remains authoritative.
local lastGain = Config.TreatsPerClick
local lastSend = 0

catButton.MouseButton1Down:Connect(function(x, y)
	local now = os.clock()
	if now - lastSend < 1 / Config.MaxClicksPerSecond then
		return -- match the server's rate so no click gets silently eaten
	end
	lastSend = now
	lastClick = now
	clickEvent:FireServer()

	popup(lastGain, x, y)
	playMeow()

	TweenService:Create(cat, squishInfo, { Size = UDim2.fromScale(0.92, 0.88) }):Play()
	task.delay(0.08, function()
		TweenService:Create(cat, unsquishInfo, { Size = UDim2.fromScale(1, 1) }):Play()
	end)
end)

clickEvent.OnClientEvent:Connect(function(gained)
	if type(gained) == "number" then
		lastGain = gained
	end
end)

-- ============================ COUNTER ============================

local function watchTreats()
	local stats = player:WaitForChild("leaderstats")
	local treats = stats:WaitForChild("Treats") :: NumberValue
	local lastPop = 0
	local function update()
		treatsLabel.Text = formatNumber(treats.Value) .. " Treats"
		-- Subtle "pop" as the number climbs (throttled)
		local now = os.clock()
		if now - lastPop > 0.35 then
			lastPop = now
			treatsLabel.TextSize = 60
			TweenService:Create(treatsLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back), { TextSize = 56 }):Play()
		end
	end
	treats.Changed:Connect(update)
	update()
end
task.spawn(watchTreats)

-- ============================ MODULES ============================

local Shop = require(script.Shop)
Shop.Start()

local SpecialCats = require(script.SpecialCats)
SpecialCats.Start()

local Stats = require(script.Stats)
Stats.Start()

local Extras = require(script.Extras)
Extras.Start()

local Pets = require(script.Pets)
Pets.Start()

local Daily = require(script.Daily)
Daily.Start()

local Store = require(script.Store)
Store.Start()

local Events = require(script.Events)
Events.Start()

local Tutorial = require(script.Tutorial)
Tutorial.Start()

print("[CatClicker] Client ready — all systems")

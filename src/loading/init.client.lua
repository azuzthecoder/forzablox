--!strict
-- Cat Clicker loading screen (ReplicatedFirst, replaces the Roblox default).
--
-- PASTE YOUR CHONKER IMAGE ID BELOW (upload the orange cat picture as a
-- Decal on create.roblox.com, then use its asset id). Until it's set, a
-- cute drawn cat face shows instead.
local CAT_IMAGE = "" -- e.g. "rbxassetid://123456789"

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ORANGE = Color3.fromRGB(235, 120, 45)
local ORANGE_SOFT = Color3.fromRGB(255, 168, 88)
local CREAM = Color3.fromRGB(255, 240, 222)
local FUR = Color3.fromRGB(233, 148, 72)
local TEXT = Color3.fromRGB(115, 70, 40)

local TIPS = {
	"Tip: the Money Cat makes the whole shop 50% off!",
	"Tip: rebirth at 500K treats for a permanent +25% boost!",
	"Tip: open eggs with Paw Coins to get meme cat pets!",
	"Tip: try the code ORANGE for free treats!",
	"Tip: Diamond Cats are rare — x15 treats!",
	"Tip: check in daily to grow your streak!",
}

local gui = Instance.new("ScreenGui")
gui.Name = "CatClickerLoading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = CREAM
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 214, 170)),
	ColorSequenceKeypoint.new(0.5, CREAM),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 150)),
})
gradient.Rotation = 90
gradient.Parent = backdrop

-- Soft glow circle behind the cat
local glow = Instance.new("Frame")
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.4)
glow.Size = UDim2.fromOffset(280, 280)
glow.BackgroundColor3 = Color3.fromRGB(255, 226, 190)
glow.BorderSizePixel = 0
local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(1, 0)
glowCorner.Parent = glow
glow.Parent = backdrop

-- The cat: your uploaded picture, or a drawn face until the id is set
local catHolder = Instance.new("Frame")
catHolder.AnchorPoint = Vector2.new(0.5, 0.5)
catHolder.Position = UDim2.fromScale(0.5, 0.4)
catHolder.Size = UDim2.fromOffset(230, 230)
catHolder.BackgroundTransparency = 1
catHolder.Parent = backdrop

if CAT_IMAGE ~= "" then
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1, 1)
	img.BackgroundTransparency = 1
	img.Image = CAT_IMAGE
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = catHolder
else
	local face = Instance.new("Frame")
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromOffset(160, 140)
	face.BackgroundColor3 = FUR
	face.BorderSizePixel = 0
	local faceCorner = Instance.new("UICorner")
	faceCorner.CornerRadius = UDim.new(0, 70)
	faceCorner.Parent = face
	face.Parent = catHolder
	for _, side in { -1, 1 } do
		local ear = Instance.new("Frame")
		ear.AnchorPoint = Vector2.new(0.5, 0.5)
		ear.Position = UDim2.new(0.5 + side * 0.3, 0, 0, 2)
		ear.Size = UDim2.fromOffset(46, 46)
		ear.Rotation = 45
		ear.BackgroundColor3 = FUR
		ear.BorderSizePixel = 0
		local earCorner = Instance.new("UICorner")
		earCorner.CornerRadius = UDim.new(0, 10)
		earCorner.Parent = ear
		ear.Parent = face
		local eye = Instance.new("Frame")
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(0.5 + side * 0.2, 0.45)
		eye.Size = UDim2.fromOffset(16, 20)
		eye.BackgroundColor3 = TEXT
		eye.BorderSizePixel = 0
		local eyeCorner = Instance.new("UICorner")
		eyeCorner.CornerRadius = UDim.new(1, 0)
		eyeCorner.Parent = eye
		eye.Parent = face
	end
	local mouth = Instance.new("TextLabel")
	mouth.AnchorPoint = Vector2.new(0.5, 0.5)
	mouth.Position = UDim2.fromScale(0.5, 0.68)
	mouth.Size = UDim2.fromOffset(50, 24)
	mouth.BackgroundTransparency = 1
	mouth.Font = Enum.Font.FredokaOne
	mouth.TextSize = 20
	mouth.TextColor3 = TEXT
	mouth.Text = "ω"
	mouth.Parent = face
end

-- Title with a chunky stroke
local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.6)
title.Size = UDim2.new(0, 600, 0, 54)
title.BackgroundTransparency = 1
title.Font = Enum.Font.FredokaOne
title.TextSize = 46
title.TextColor3 = ORANGE_SOFT
title.Text = "🐾 CAT CLICKER 🐾"
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = ORANGE
titleStroke.Thickness = 2.5
titleStroke.Parent = title
title.Parent = backdrop

local paws = Instance.new("TextLabel")
paws.AnchorPoint = Vector2.new(0.5, 0.5)
paws.Position = UDim2.fromScale(0.5, 0.68)
paws.Size = UDim2.new(0, 300, 0, 30)
paws.BackgroundTransparency = 1
paws.Font = Enum.Font.FredokaOne
paws.TextSize = 20
paws.TextColor3 = TEXT
paws.Text = "loading"
paws.Parent = backdrop

local tip = Instance.new("TextLabel")
tip.AnchorPoint = Vector2.new(0.5, 1)
tip.Position = UDim2.new(0.5, 0, 1, -30)
tip.Size = UDim2.new(0, 640, 0, 26)
tip.BackgroundTransparency = 1
tip.Font = Enum.Font.FredokaOne
tip.TextSize = 17
tip.TextColor3 = ORANGE
tip.Text = TIPS[math.random(#TIPS)]
tip.Parent = backdrop

-- Animations: cat bob + glow pulse + paw dots + cycling tips
local done = false
task.spawn(function()
	local dots = 0
	local tipIndex = math.random(#TIPS)
	local lastTipSwap = os.clock()
	while not done do
		TweenService:Create(catHolder, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
			Position = UDim2.new(0.5, 0, 0.4, -8),
		}):Play()
		TweenService:Create(glow, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
			Size = UDim2.fromOffset(300, 300),
		}):Play()
		task.wait(0.7)
		TweenService:Create(catHolder, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
			Position = UDim2.new(0.5, 0, 0.4, 8),
		}):Play()
		TweenService:Create(glow, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
			Size = UDim2.fromOffset(270, 270),
		}):Play()
		dots = (dots % 3) + 1
		paws.Text = "loading " .. string.rep("🐾", dots)
		if os.clock() - lastTipSwap > 4 then
			lastTipSwap = os.clock()
			tipIndex = (tipIndex % #TIPS) + 1
			tip.Text = TIPS[tipIndex]
		end
		task.wait(0.7)
	end
end)

-- Hold until loaded (minimum 2.5s so it never just flashes)
local shownAt = os.clock()
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(math.max(0, 2.5 - (os.clock() - shownAt)))

done = true
for _, child in backdrop:GetDescendants() do
	if child:IsA("TextLabel") then
		TweenService:Create(child, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	elseif child:IsA("ImageLabel") then
		TweenService:Create(child, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
	elseif child:IsA("UIStroke") then
		TweenService:Create(child, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	end
end
local fade = TweenService:Create(backdrop, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1,
})
fade:Play()
fade.Completed:Wait()
gui:Destroy()

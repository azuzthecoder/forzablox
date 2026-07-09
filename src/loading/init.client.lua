--!strict
-- Cat-themed loading screen. Lives in ReplicatedFirst so it appears the
-- moment the player joins, replacing Roblox's default loading UI.
-- (Colors are hardcoded here because ReplicatedStorage may not have
-- replicated yet when this runs.)

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ORANGE = Color3.fromRGB(235, 120, 45)
local CREAM = Color3.fromRGB(255, 240, 222)
local FUR = Color3.fromRGB(233, 148, 72)
local TEXT = Color3.fromRGB(115, 70, 40)

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

-- Simple cat face
local face = Instance.new("Frame")
face.AnchorPoint = Vector2.new(0.5, 0.5)
face.Position = UDim2.fromScale(0.5, 0.42)
face.Size = UDim2.fromOffset(150, 130)
face.BackgroundColor3 = FUR
face.BorderSizePixel = 0
local faceCorner = Instance.new("UICorner")
faceCorner.CornerRadius = UDim.new(0, 65)
faceCorner.Parent = face
face.Parent = backdrop

for _, side in { -1, 1 } do
	local ear = Instance.new("Frame")
	ear.AnchorPoint = Vector2.new(0.5, 0.5)
	ear.Position = UDim2.new(0.5 + side * 0.3, 0, 0, 4)
	ear.Size = UDim2.fromOffset(44, 44)
	ear.Rotation = 45
	ear.BackgroundColor3 = FUR
	ear.BorderSizePixel = 0
	local earCorner = Instance.new("UICorner")
	earCorner.CornerRadius = UDim.new(0, 10)
	earCorner.Parent = ear
	ear.ZIndex = 0
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

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.58)
title.Size = UDim2.new(0, 500, 0, 44)
title.BackgroundTransparency = 1
title.Font = Enum.Font.FredokaOne
title.TextSize = 38
title.TextColor3 = ORANGE
title.Text = "🐾 Cat Clicker 🐾"
title.Parent = backdrop

local paws = Instance.new("TextLabel")
paws.AnchorPoint = Vector2.new(0.5, 0.5)
paws.Position = UDim2.fromScale(0.5, 0.66)
paws.Size = UDim2.new(0, 300, 0, 30)
paws.BackgroundTransparency = 1
paws.Font = Enum.Font.FredokaOne
paws.TextSize = 20
paws.TextColor3 = TEXT
paws.Text = "loading"
paws.Parent = backdrop

-- Wobble the face + animate loading paws while the game streams in
local done = false
task.spawn(function()
	local dots = 0
	while not done do
		TweenService:Create(face, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
			Rotation = 6,
		}):Play()
		task.wait(0.4)
		TweenService:Create(face, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
			Rotation = -6,
		}):Play()
		dots = (dots % 3) + 1
		paws.Text = "loading " .. string.rep("🐾", dots)
		task.wait(0.4)
	end
end)

-- Hold until the game is loaded (with a minimum so it never just flashes)
local shownAt = os.clock()
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(math.max(0, 2 - (os.clock() - shownAt)))

done = true
local fade = TweenService:Create(backdrop, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1,
})
for _, child in backdrop:GetDescendants() do
	if child:IsA("TextLabel") then
		TweenService:Create(child, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end
end
fade:Play()
fade.Completed:Wait()
gui:Destroy()

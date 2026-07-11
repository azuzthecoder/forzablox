--!strict
-- Special bonus cats: Silver (x3), Golden (x7), Diamond (x15) and the
-- Money Cat (50% off the shop). The server offers one on a random schedule;
-- it drifts across the screen and clicking it activates its effect.
-- Active effects show as colored countdown banners under the counter.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SpecialCats = {}

local player = Players.LocalPlayer
local rng = Random.new()

local gui: ScreenGui
local activeCat: TextButton? = nil

type Banner = { frame: TextLabel, endsAt: number, text: string }
local banners: { [string]: Banner } = {} -- "boost" | "discount"

local function typeColor(catType: any): Color3
	return Color3.fromRGB(catType.color[1], catType.color[2], catType.color[3])
end

local function removeCat()
	if activeCat then
		activeCat:Destroy()
		activeCat = nil
	end
end

local function spawnCat(catType: any, window: number, onClicked: () -> ())
	removeCat()
	local color = typeColor(catType)

	local cat = Instance.new("TextButton")
	activeCat = cat
	cat.Size = UDim2.fromOffset(90, 90)
	cat.BackgroundColor3 = color
	cat.Text = catType.emoji
	cat.TextSize = 44
	cat.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = cat
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7)
	stroke.Thickness = 3
	stroke.Parent = cat

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Size = UDim2.new(2, 0, 0, 20)
	tag.Position = UDim2.new(-0.5, 0, -0.32, 0)
	tag.Font = Enum.Font.FredokaOne
	tag.TextSize = 15
	tag.TextColor3 = Color3.new(color.R * 0.6, color.G * 0.6, color.B * 0.6)
	tag.TextStrokeColor3 = Color3.new(1, 1, 1)
	tag.TextStrokeTransparency = 0.5
	tag.Text = "✨ " .. catType.name .. " ✨"
	tag.Parent = cat

	local leftToRight = rng:NextNumber() > 0.5
	local y = rng:NextNumber(0.22, 0.72)
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

	task.spawn(function()
		while cat.Parent do
			TweenService:Create(cat, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Rotation = 8 }):Play()
			task.wait(0.5)
			TweenService:Create(cat, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Rotation = -8 }):Play()
			task.wait(0.5)
		end
	end)

	cat.MouseButton1Click:Connect(function()
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

local function setBanner(kind: string, catType: any, text: string, duration: number)
	local banner = banners[kind]
	if not banner then
		-- Compact pill in the top strip, clear of the big cat
		local frame = Instance.new("TextLabel")
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Size = UDim2.new(0, 400, 0, 26)
		frame.Position = UDim2.new(0.5, 0, 0, 164 + (kind == "discount" and 30 or 0))
		frame.Font = Enum.Font.FredokaOne
		frame.TextSize = 15
		frame.Visible = false
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = frame
		frame.Parent = gui
		banner = { frame = frame, endsAt = 0, text = "" }
		banners[kind] = banner
	end
	local color = typeColor(catType)
	banner.frame.BackgroundColor3 = color
	banner.frame.TextColor3 = Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)
	banner.endsAt = os.clock() + duration
	banner.text = text
	banner.frame.Visible = true
end

function SpecialCats.Start()
	local offerEvent = ReplicatedStorage:WaitForChild("GoldenCatOffer") :: RemoteEvent
	local clickEvent = ReplicatedStorage:WaitForChild("GoldenCatClick") :: RemoteEvent
	local boostSync = ReplicatedStorage:WaitForChild("BoostSync") :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerSpecial"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 40
	gui.Parent = player:WaitForChild("PlayerGui")

	offerEvent.OnClientEvent:Connect(function(typeId, window)
		local catType = Config.SpecialCatsById[typeId]
		if catType then
			spawnCat(catType, type(window) == "number" and window or 12, function()
				clickEvent:FireServer()
			end)
		end
	end)

	boostSync.OnClientEvent:Connect(function(kind, typeId, magnitude, duration)
		local catType = Config.SpecialCatsById[typeId]
		if not catType or type(duration) ~= "number" then
			return
		end
		if kind == "boost" then
			setBanner("boost", catType,
				("%s %s!  x%d treats for %%ds"):format(catType.emoji, catType.name:upper(), magnitude),
				duration)
		elseif kind == "discount" then
			setBanner("discount", catType,
				catType.emoji .. " MONEY CAT!  Shop 50%% off for %ds",
				duration)
		end
	end)

	RunService.RenderStepped:Connect(function()
		for _, banner in banners do
			if banner.frame.Visible then
				local remaining = banner.endsAt - os.clock()
				if remaining <= 0 then
					banner.frame.Visible = false
				else
					banner.frame.Text = banner.text:format(math.ceil(remaining))
				end
			end
		end
	end)
end

return SpecialCats

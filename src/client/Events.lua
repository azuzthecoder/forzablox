--!strict
-- Mutation events: Acid Rain, Nightfall and Shooting Stars. The server
-- broadcasts them; this module restyles the whole screen (tint + weather
-- particles) and shows a big announcement banner with the buff.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Events = {}

local player = Players.LocalPlayer
local rng = Random.new()

local gui: ScreenGui
local activeFolder: Frame? = nil
local activeEndsAt = 0
local banner: Frame
local bannerTitle: TextLabel
local bannerDesc: TextLabel
local bannerTime: TextLabel

local function clearEvent()
	if activeFolder then
		activeFolder:Destroy()
		activeFolder = nil
	end
	banner.Visible = false
end

local function startEvent(eventId: string, duration: number)
	local event = Config.EventsById[eventId]
	if not event then
		return
	end
	clearEvent()
	activeEndsAt = os.clock() + duration

	local color = Color3.fromRGB(event.color[1], event.color[2], event.color[3])

	local folder = Instance.new("Frame")
	folder.Size = UDim2.fromScale(1, 1)
	folder.BackgroundTransparency = 1
	folder.Parent = gui
	activeFolder = folder

	-- Screen tint (never blocks clicks)
	local tint = Instance.new("Frame")
	tint.Size = UDim2.fromScale(1, 1)
	tint.BorderSizePixel = 0
	tint.Active = false
	tint.BackgroundColor3 = color
	tint.BackgroundTransparency = 1
	tint.Parent = folder
	TweenService:Create(tint, TweenInfo.new(1.2), {
		BackgroundTransparency = eventId == "nightfall" and 0.72 or 0.85,
	}):Play()
	if eventId == "nightfall" then
		tint.BackgroundColor3 = Color3.fromRGB(30, 30, 80)
	end

	-- Announcement pill (single line, stays above the cat)
	banner.Visible = true
	banner.BackgroundColor3 = color
	bannerTitle.Text = ("%s %s — %s"):format(event.emoji, event.name, event.desc)
	banner.Size = UDim2.new(0, 200, 0, 24)
	TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 500, 0, 28),
	}):Play()

	-- Weather particles
	task.spawn(function()
		while activeFolder == folder and os.clock() < activeEndsAt do
			local particle = Instance.new("TextLabel")
			particle.BackgroundTransparency = 1
			particle.Font = Enum.Font.FredokaOne
			particle.TextTransparency = 0.25

			if eventId == "acidrain" then
				particle.Text = "💧"
				particle.TextColor3 = color
				particle.TextSize = rng:NextInteger(18, 30)
				particle.Position = UDim2.new(rng:NextNumber(0, 1), 0, -0.05, 0)
				particle.Size = UDim2.fromOffset(30, 30)
				particle.Parent = folder
				TweenService:Create(particle, TweenInfo.new(rng:NextNumber(0.8, 1.4), Enum.EasingStyle.Linear), {
					Position = particle.Position + UDim2.fromScale(0.02, 1.15),
					TextTransparency = 0.6,
				}):Play()
				task.delay(1.5, function()
					particle:Destroy()
				end)
				task.wait(0.06)
			elseif eventId == "nightfall" then
				particle.Text = rng:NextNumber() < 0.15 and "🌙" or "⭐"
				particle.TextSize = rng:NextInteger(14, 26)
				particle.Position = UDim2.new(rng:NextNumber(0, 1), 0, rng:NextNumber(0, 0.6), 0)
				particle.Size = UDim2.fromOffset(30, 30)
				particle.TextTransparency = 1
				particle.Parent = folder
				TweenService:Create(particle, TweenInfo.new(0.8), { TextTransparency = 0.15 }):Play()
				task.delay(2.2, function()
					if particle.Parent then
						local fade = TweenService:Create(particle, TweenInfo.new(0.8), { TextTransparency = 1 })
						fade.Completed:Connect(function()
							particle:Destroy()
						end)
						fade:Play()
					end
				end)
				task.wait(0.25)
			else -- shooting stars
				particle.Text = "🌠"
				particle.TextSize = rng:NextInteger(24, 40)
				particle.Position = UDim2.new(rng:NextNumber(0.2, 1.05), 0, -0.05, 0)
				particle.Size = UDim2.fromOffset(44, 44)
				particle.Rotation = 15
				particle.Parent = folder
				TweenService:Create(particle, TweenInfo.new(rng:NextNumber(1, 1.8), Enum.EasingStyle.Linear), {
					Position = particle.Position + UDim2.fromScale(-0.5, 1.2),
					TextTransparency = 0.5,
				}):Play()
				task.delay(2, function()
					particle:Destroy()
				end)
				task.wait(0.18)
			end
		end

		if activeFolder == folder then
			-- fade out
			TweenService:Create(tint, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
			task.wait(1.3)
			if activeFolder == folder then
				clearEvent()
			end
		end
	end)
end

function Events.Start()
	local globalEvent = ReplicatedStorage:WaitForChild("GlobalEvent") :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerEvents"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Compact pill in the top strip, third row under the special-cat pills
	banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 224)
	banner.Size = UDim2.new(0, 500, 0, 28)
	banner.BorderSizePixel = 0
	banner.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = banner
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = banner
	banner.Parent = gui

	bannerTitle = Instance.new("TextLabel")
	bannerTitle.BackgroundTransparency = 1
	bannerTitle.Size = UDim2.new(1, -70, 1, 0)
	bannerTitle.Position = UDim2.new(0, 12, 0, 0)
	bannerTitle.Font = Enum.Font.FredokaOne
	bannerTitle.TextSize = 15
	bannerTitle.TextColor3 = Color3.new(1, 1, 1)
	bannerTitle.TextStrokeTransparency = 0.6
	bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
	bannerTitle.TextTruncate = Enum.TextTruncate.AtEnd
	bannerTitle.Text = ""
	bannerTitle.Parent = banner

	bannerTime = Instance.new("TextLabel")
	bannerTime.BackgroundTransparency = 1
	bannerTime.AnchorPoint = Vector2.new(1, 0)
	bannerTime.Position = UDim2.new(1, -12, 0, 0)
	bannerTime.Size = UDim2.new(0, 50, 1, 0)
	bannerTime.Font = Enum.Font.FredokaOne
	bannerTime.TextSize = 14
	bannerTime.TextColor3 = Color3.new(1, 1, 1)
	bannerTime.TextXAlignment = Enum.TextXAlignment.Right
	bannerTime.Text = ""
	bannerTime.Parent = banner

	RunService.RenderStepped:Connect(function()
		if banner.Visible then
			local remaining = activeEndsAt - os.clock()
			bannerTime.Text = remaining > 0 and ("%ds"):format(math.ceil(remaining)) or ""
		end
	end)

	globalEvent.OnClientEvent:Connect(function(eventId, duration)
		if type(eventId) == "string" and type(duration) == "number" then
			startEvent(eventId, duration)
		end
	end)
	globalEvent:FireServer() -- ask if an event is already running
end

return Events

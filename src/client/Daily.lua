--!strict
-- Daily rewards: a check-in (streak = more Paw Coins) and a once-a-day
-- prize spinner with a cycling reveal animation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Daily = {}

local player = Players.LocalPlayer
local C = Config.Colors

local function round(instance: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius > 0 and UDim.new(0, radius) or UDim.new(1, 0)
	corner.Parent = instance
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = C.Text
	l.TextXAlignment = Enum.TextXAlignment.Center
	for key, value in props do
		(l :: any)[key] = value
	end
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string, props: { [string]: any }): TextButton
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = C.Pink
	b.BorderSizePixel = 0
	b.Font = Enum.Font.FredokaOne
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 16
	for key, value in props do
		(b :: any)[key] = value
	end
	round(b, 10)
	b.Parent = parent
	return b
end

function Daily.Start()
	local dailyState = ReplicatedStorage:WaitForChild("DailyState") :: RemoteFunction
	local checkIn = ReplicatedStorage:WaitForChild("CheckIn") :: RemoteFunction
	local spin = ReplicatedStorage:WaitForChild("SpinWheel") :: RemoteFunction

	local gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerDaily"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 25
	gui.Parent = player:WaitForChild("PlayerGui")

	local toggle = button(gui, "🎡", {
		Position = UDim2.new(0, 12, 0, 408),
		Size = UDim2.new(0, 46, 0, 46),
		TextSize = 22,
	})
	round(toggle, 0)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 400, 0, 430)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	round(panel, 18)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Accent
	stroke.Thickness = 2
	stroke.Parent = panel
	panel.Parent = gui

	label(panel, {
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 0, 28),
		TextSize = 22,
		TextColor3 = C.PinkDark,
		Text = "🎁 Daily Rewards",
	})
	local close = button(panel, "✕", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0, 32, 0, 28),
		BackgroundColor3 = C.Background,
		TextColor3 = C.Text,
		TextSize = 14,
	})
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	-- ============== Check-in section ==============
	local checkPane = Instance.new("Frame")
	checkPane.Position = UDim2.new(0, 16, 0, 50)
	checkPane.Size = UDim2.new(1, -32, 0, 120)
	checkPane.BackgroundColor3 = C.Background
	checkPane.BorderSizePixel = 0
	round(checkPane, 14)
	checkPane.Parent = panel

	local streakLabel = label(checkPane, {
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 17,
		Text = "📅 Daily Check-In",
	})
	local checkInfo = label(checkPane, {
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 18),
		TextSize = 13,
		TextColor3 = C.TextSoft,
		Text = "Come back daily for a bigger streak bonus!",
	})
	local checkBtn = button(checkPane, "CLAIM", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundColor3 = C.PinkDark,
	})

	-- ============== Spinner section ==============
	local spinPane = Instance.new("Frame")
	spinPane.Position = UDim2.new(0, 16, 0, 182)
	spinPane.Size = UDim2.new(1, -32, 0, 230)
	spinPane.BackgroundColor3 = C.Background
	spinPane.BorderSizePixel = 0
	round(spinPane, 14)
	spinPane.Parent = panel

	label(spinPane, {
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 17,
		Text = "🎡 Lucky Spinner",
	})

	local prizeDisplay = Instance.new("Frame")
	prizeDisplay.AnchorPoint = Vector2.new(0.5, 0)
	prizeDisplay.Position = UDim2.new(0.5, 0, 0, 42)
	prizeDisplay.Size = UDim2.new(1, -40, 0, 90)
	prizeDisplay.BackgroundColor3 = C.Panel
	prizeDisplay.BorderSizePixel = 0
	round(prizeDisplay, 12)
	local prizeStroke = Instance.new("UIStroke")
	prizeStroke.Color = C.Accent
	prizeStroke.Thickness = 3
	prizeStroke.Parent = prizeDisplay
	prizeDisplay.Parent = spinPane

	local prizeIcon = label(prizeDisplay, {
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, 0, 0, 40),
		TextSize = 34,
		Text = "❓",
	})
	local prizeName = label(prizeDisplay, {
		Position = UDim2.new(0, 0, 0, 52),
		Size = UDim2.new(1, 0, 0, 26),
		TextSize = 17,
		Text = "Spin for a daily prize!",
	})

	local spinBtn = button(spinPane, "SPIN!", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -32, 0, 44),
		BackgroundColor3 = C.PinkDark,
		TextSize = 20,
	})

	-- ============== State / behaviour ==============
	local spinning = false

	local function refresh()
		task.spawn(function()
			local state = dailyState:InvokeServer()
			if type(state) ~= "table" then
				return
			end
			streakLabel.Text = ("📅 Daily Check-In  •  Streak: %d🔥"):format(state.streak or 0)
			if state.canCheckIn then
				checkBtn.Text = "CLAIM TODAY'S COINS"
				checkBtn.BackgroundColor3 = C.PinkDark
			else
				checkBtn.Text = "✓ CLAIMED — BACK TOMORROW"
				checkBtn.BackgroundColor3 = C.PanelShadow
			end
			if state.canSpin then
				spinBtn.Text = "SPIN!"
				spinBtn.BackgroundColor3 = C.PinkDark
			else
				spinBtn.Text = "✓ SPUN — BACK TOMORROW"
				spinBtn.BackgroundColor3 = C.PanelShadow
			end
		end)
	end

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			refresh()
		end
	end)

	checkBtn.MouseButton1Click:Connect(function()
		local ok, result, streak = checkIn:InvokeServer()
		if ok then
			checkInfo.Text = ("+%d Paw Coins! 🔥 %d-day streak"):format(result, streak)
			checkInfo.TextColor3 = Color3.fromRGB(90, 170, 100)
		else
			checkInfo.Text = tostring(result)
			checkInfo.TextColor3 = C.TextSoft
		end
		refresh()
	end)

	spinBtn.MouseButton1Click:Connect(function()
		if spinning then
			return
		end
		local ok, result = spin:InvokeServer()
		if not ok then
			prizeName.Text = tostring(result)
			return
		end

		-- Cycle through prizes, slowing down, landing on the server's pick
		spinning = true
		local prizes = Config.Daily.SpinPrizes
		local n = #prizes
		local finalIndex = result :: number
		local steps = n * 2 + finalIndex
		local delay = 0.05
		local index = 0
		for step = 1, steps do
			index = (index % n) + 1
			local prize = prizes[index] :: any
			prizeIcon.Text = prize.icon
			prizeName.Text = prize.name
			prizeStroke.Color = C.PanelShadow
			task.wait(delay)
			-- ease out over the last stretch
			if step > steps - 8 then
				delay *= 1.35
			end
		end
		local prize = prizes[finalIndex] :: any
		prizeIcon.Text = prize.icon
		prizeName.Text = "🎉 " .. prize.name .. " 🎉"
		prizeStroke.Color = C.Accent
		spinning = false
		refresh()
	end)
end

return Daily

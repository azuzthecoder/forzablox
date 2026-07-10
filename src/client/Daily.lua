--!strict
-- Daily rewards: a 7-day login calendar (shows exactly what each day pays)
-- and a real spinning prize wheel. Auto-opens on join when something is
-- claimable.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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

	-- Bubble toggle button
	local toggle = button(gui, "", {
		Position = UDim2.new(0, 12, 0, 416),
		Size = UDim2.new(0, 158, 0, 58),
		BackgroundColor3 = C.Panel,
	})
	round(toggle, 20)
	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = C.Accent
	toggleStroke.Thickness = 3
	toggleStroke.Parent = toggle
	local toggleText = label(toggle, {
		Size = UDim2.fromScale(1, 1),
		TextSize = 22,
		TextColor3 = C.PinkDark,
		Text = "🎡 DAILY",
	})
	local toggleTextStroke = Instance.new("UIStroke")
	toggleTextStroke.Color = Color3.new(1, 1, 1)
	toggleTextStroke.Thickness = 1.5
	toggleTextStroke.Parent = toggleText
	task.spawn(function()
		task.wait(0.5)
		while toggle.Parent do
			TweenService:Create(toggle, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 12, 0, 422),
			}):Play()
			task.wait(1.4)
			TweenService:Create(toggle, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 12, 0, 416),
			}):Play()
			task.wait(1.4)
		end
	end)

	-- ============== Panel ==============
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 560, 0, 620)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	round(panel, 22)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Accent
	stroke.Thickness = 3
	stroke.Parent = panel
	panel.Parent = gui

	local title = label(panel, {
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 26,
		TextColor3 = C.PinkDark,
		Text = "🎁 Daily Rewards",
	})
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(1, 1, 1)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = title

	local close = button(panel, "✕", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.new(0, 34, 0, 30),
		BackgroundColor3 = C.Background,
		TextColor3 = C.Text,
		TextSize = 14,
	})
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	-- ============== 7-day calendar ==============
	local streakLabel = label(panel, {
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 15,
		TextColor3 = C.TextSoft,
		Text = "📅 Login Calendar  •  Streak: 0🔥",
	})

	local tiles: { Frame } = {}
	local rewards = Config.Daily.CheckInRewards
	for i, reward in rewards do
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		local tile = Instance.new("Frame")
		tile.Position = UDim2.new(0, 20 + col * 132, 0, 72 + row * 92)
		tile.Size = UDim2.new(0, 124, 0, 84)
		tile.BackgroundColor3 = C.Background
		tile.BorderSizePixel = 0
		round(tile, 12)
		local tileStroke = Instance.new("UIStroke")
		tileStroke.Name = "TileStroke"
		tileStroke.Color = C.PanelShadow
		tileStroke.Thickness = 2
		tileStroke.Parent = tile
		tile.Parent = panel
		tiles[i] = tile

		label(tile, {
			Position = UDim2.new(0, 0, 0, 4),
			Size = UDim2.new(1, 0, 0, 16),
			TextSize = 12,
			TextColor3 = C.TextSoft,
			Text = "DAY " .. i,
		})
		label(tile, {
			Position = UDim2.new(0, 0, 0, 20),
			Size = UDim2.new(1, 0, 0, 28),
			TextSize = 22,
			Text = (reward :: any).icon,
		})
		label(tile, {
			Position = UDim2.new(0, 4, 0, 48),
			Size = UDim2.new(1, -8, 0, 32),
			TextSize = 11,
			TextWrapped = true,
			Text = (reward :: any).name,
		})
	end

	local checkBtn = button(panel, "CLAIM TODAY'S REWARD", {
		Position = UDim2.new(0, 20, 0, 262),
		Size = UDim2.new(1, -40, 0, 42),
		BackgroundColor3 = C.PinkDark,
		TextSize = 17,
	})

	-- ============== Spinning wheel ==============
	label(panel, {
		Position = UDim2.new(0, 0, 0, 312),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 16,
		TextColor3 = C.TextSoft,
		Text = "🎡 Lucky Spinner — one free spin a day!",
	})

	label(panel, { -- pointer
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 330),
		Size = UDim2.new(0, 30, 0, 22),
		TextSize = 20,
		TextColor3 = C.PinkDark,
		Text = "▼",
	}).ZIndex = 5

	local wheel = Instance.new("Frame")
	wheel.AnchorPoint = Vector2.new(0.5, 0)
	wheel.Position = UDim2.new(0.5, 0, 0, 350)
	wheel.Size = UDim2.new(0, 190, 0, 190)
	wheel.BackgroundColor3 = C.Background
	wheel.BorderSizePixel = 0
	round(wheel, 95)
	local wheelStroke = Instance.new("UIStroke")
	wheelStroke.Color = C.Accent
	wheelStroke.Thickness = 4
	wheelStroke.Parent = wheel
	wheel.Parent = panel

	local prizes = Config.Daily.SpinPrizes
	for i, prize in prizes do
		local holder = Instance.new("Frame")
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.Rotation = (i - 1) * (360 / #prizes)
		holder.Parent = wheel
		label(holder, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8),
			Size = UDim2.new(0, 30, 0, 28),
			TextSize = 22,
			Text = (prize :: any).icon,
		})
	end
	local hub = Instance.new("Frame")
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.Size = UDim2.new(0, 56, 0, 56)
	hub.BackgroundColor3 = C.Panel
	hub.BorderSizePixel = 0
	round(hub, 28)
	hub.Parent = wheel
	label(hub, {
		Size = UDim2.fromScale(1, 1),
		TextSize = 24,
		Text = "🐾",
	})

	local prizeName = label(panel, {
		Position = UDim2.new(0, 0, 0, 546),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 16,
		Text = "What will you win today?",
	})

	local spinBtn = button(panel, "SPIN!", {
		Position = UDim2.new(0, 20, 1, -46),
		Size = UDim2.new(1, -40, 0, 36),
		BackgroundColor3 = C.PinkDark,
		TextSize = 18,
	})

	-- ============== Behaviour ==============
	local spinning = false

	local function refresh()
		task.spawn(function()
			local state = dailyState:InvokeServer()
			if type(state) ~= "table" then
				return
			end
			local streak = state.streak or 0
			streakLabel.Text = ("📅 Login Calendar  •  Streak: %d🔥"):format(streak)

			-- Highlight today's tile (next unclaimed day in the 7-day cycle)
			local todayIndex = state.canCheckIn
				and (streak % #rewards) + 1
				or ((streak - 1) % #rewards) + 1
			for i, tile in tiles do
				local tileStroke = tile:FindFirstChild("TileStroke") :: UIStroke
				if i == todayIndex then
					tileStroke.Color = C.Accent
					tileStroke.Thickness = 3
					tile.BackgroundColor3 = Color3.fromRGB(255, 246, 224)
				else
					tileStroke.Color = C.PanelShadow
					tileStroke.Thickness = 2
					tile.BackgroundColor3 = C.Background
				end
			end

			if state.canCheckIn then
				checkBtn.Text = "CLAIM TODAY'S REWARD"
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
		local ok, result, _streak = checkIn:InvokeServer()
		if ok and type(result) == "number" then
			local reward = rewards[result] :: any
			prizeName.Text = "🎉 Day " .. result .. " claimed: " .. reward.name .. "!"
			prizeName.TextColor3 = Color3.fromRGB(90, 170, 100)
		else
			prizeName.Text = tostring(result)
			prizeName.TextColor3 = C.TextSoft
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
			prizeName.TextColor3 = C.TextSoft
			return
		end

		spinning = true
		local finalIndex = result :: number
		local slice = 360 / #prizes
		-- Land the winning slice under the top pointer after 5 full spins
		local target = 360 * 5 + (360 - (finalIndex - 1) * slice)
		wheel.Rotation = 0
		prizeName.Text = "Spinning..."
		prizeName.TextColor3 = C.Text
		local tween = TweenService:Create(wheel,
			TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = target })
		tween.Completed:Connect(function()
			local prize = prizes[finalIndex] :: any
			prizeName.Text = "🎉 " .. prize.name .. " 🎉"
			prizeName.TextColor3 = C.PinkDark
			spinning = false
			refresh()
		end)
		tween:Play()
	end)

	-- Auto-open on join when something is claimable (waits out the tutorial)
	task.spawn(function()
		task.wait(player:GetAttribute("FirstJoin") and 30 or 6)
		local state = dailyState:InvokeServer()
		if type(state) == "table" and (state.canCheckIn or state.canSpin) then
			panel.Visible = true
			refresh()
		end
	end)
end

return Daily

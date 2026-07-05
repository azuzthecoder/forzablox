--!strict
-- Stage 5: stats panel (total earned, per second, clicks) and the global
-- top-10 leaderboard, both on the left side of the screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Stats = {}

local player = Players.LocalPlayer
local C = Config.Colors

local function round(instance: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = C.Text
	l.TextXAlignment = Enum.TextXAlignment.Left
	for key, value in props do
		(l :: any)[key] = value
	end
	l.Parent = parent
	return l
end

local function formatNumber(n: number): string
	if n >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	end
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

function Stats.Start()
	local leaderboardSync = ReplicatedStorage:WaitForChild("LeaderboardSync") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerStats"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	-- ============== Leaderboard (top left) ==============
	local board = Instance.new("Frame")
	board.Position = UDim2.new(0, 12, 0, 12)
	board.Size = UDim2.new(0, 250, 0, 330)
	board.BackgroundColor3 = C.Panel
	board.BackgroundTransparency = 0.06
	board.BorderSizePixel = 0
	round(board, 18)
	board.Parent = gui

	label(board, {
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -32, 0, 26),
		TextSize = 20,
		TextColor3 = C.PinkDark,
		Text = "🏆 Top Cats",
	})

	local rows: { TextLabel } = {}
	for i = 1, 10 do
		local row = label(board, {
			Position = UDim2.new(0, 16, 0, 40 + (i - 1) * 28),
			Size = UDim2.new(1, -32, 0, 24),
			TextSize = 15,
			TextColor3 = i <= 3 and C.Accent or C.Text,
			Text = i .. ".  —",
		})
		rows[i] = row
	end

	leaderboardSync.OnClientEvent:Connect(function(top)
		if type(top) ~= "table" then
			return
		end
		for i = 1, 10 do
			local entry = top[i]
			if entry then
				rows[i].Text = ("%d.  %s  —  %s"):format(i, tostring(entry.name), formatNumber(entry.score))
			else
				rows[i].Text = i .. ".  —"
			end
		end
	end)

	-- ============== Stats panel (bottom left) ==============
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 12, 1, -12)
	panel.Size = UDim2.new(0, 250, 0, 168)
	panel.BackgroundColor3 = C.Panel
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	round(panel, 18)
	panel.Parent = gui

	label(panel, {
		Position = UDim2.new(0, 16, 0, 8),
		Size = UDim2.new(1, -32, 0, 24),
		TextSize = 18,
		TextColor3 = C.PinkDark,
		Text = "📊 Stats",
	})
	local earnedLabel = label(panel, {
		Position = UDim2.new(0, 16, 0, 36),
		Size = UDim2.new(1, -32, 0, 22),
		TextSize = 14,
		Text = "Total earned: 0",
	})
	local tpsLabel = label(panel, {
		Position = UDim2.new(0, 16, 0, 60),
		Size = UDim2.new(1, -32, 0, 22),
		TextSize = 14,
		Text = "Per second: 0",
	})
	local clicksLabel = label(panel, {
		Position = UDim2.new(0, 16, 0, 84),
		Size = UDim2.new(1, -32, 0, 22),
		TextSize = 14,
		Text = "Clicks: 0",
	})
	local catPointsLabel = label(panel, {
		Position = UDim2.new(0, 16, 0, 108),
		Size = UDim2.new(1, -32, 0, 22),
		TextSize = 14,
		TextColor3 = C.PinkDark,
		Text = "Cat Points: 0",
	})

	local timeLabel = label(panel, {
		Position = UDim2.new(0, 16, 0, 132),
		Size = UDim2.new(1, -32, 0, 22),
		TextSize = 14,
		Text = "Time played: 0m 0s",
	})

	-- Time played ticker (base resets when a save loads or is wiped)
	local sessionStart = os.clock()
	player:GetAttributeChangedSignal("PlaytimeBase"):Connect(function()
		sessionStart = os.clock()
	end)
	task.spawn(function()
		while true do
			local total = ((player:GetAttribute("PlaytimeBase") :: number?) or 0) + (os.clock() - sessionStart)
			local h = math.floor(total / 3600)
			local m = math.floor((total % 3600) / 60)
			local s = math.floor(total % 60)
			timeLabel.Text = h > 0 and ("Time played: %dh %dm %ds"):format(h, m, s)
				or ("Time played: %dm %ds"):format(m, s)
			task.wait(1)
		end
	end)

	local function updateStats()
		earnedLabel.Text = "Total earned: " .. formatNumber((player:GetAttribute("TotalEarned") :: number?) or 0)
		local perSecond = (player:GetAttribute("PerSecond") :: number?) or 0
		tpsLabel.Text = "Per second: " .. (perSecond < 1 and string.format("%.1f", perSecond) or formatNumber(perSecond))
		clicksLabel.Text = "Clicks: " .. formatNumber((player:GetAttribute("Clicks") :: number?) or 0)
		local catPoints = (player:GetAttribute("CatPoints") :: number?) or 0
		catPointsLabel.Text = ("Cat Points: %d  (+%d%%/sec)"):format(
			catPoints, catPoints * Config.Prestige.BoostPerPoint * 100)
	end
	player:GetAttributeChangedSignal("TotalEarned"):Connect(updateStats)
	player:GetAttributeChangedSignal("PerSecond"):Connect(updateStats)
	player:GetAttributeChangedSignal("Clicks"):Connect(updateStats)
	player:GetAttributeChangedSignal("CatPoints"):Connect(updateStats)
	updateStats()
end

return Stats

--!strict
-- Rebirth button (with confirm popup), redeemable codes panel, and a
-- settings/info panel with playtime + group placeholder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Extras = {}

local player = Players.LocalPlayer
local C = Config.Colors

-- PlaytimeBase changes when a save loads or the save is reset; restart the
-- session clock then so playtime = base + time since that moment.
local sessionStart = os.clock()
player:GetAttributeChangedSignal("PlaytimeBase"):Connect(function()
	sessionStart = os.clock()
end)

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
	b.TextSize = 18
	for key, value in props do
		(b :: any)[key] = value
	end
	round(b, 12)
	b.Parent = parent
	return b
end

local function modal(gui: ScreenGui, title: string, height: number): (Frame, Frame)
	local overlay = Instance.new("TextButton")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Visible = false
	overlay.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.45)
	panel.Size = UDim2.new(0, 360, 0, height)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	round(panel, 18)
	panel.Parent = overlay

	label(panel, {
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(1, 0, 0, 28),
		TextSize = 22,
		TextColor3 = C.PinkDark,
		Text = title,
	})
	local closeBtn = button(panel, "✕", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 30, 0, 28),
		BackgroundColor3 = C.Background,
		TextColor3 = C.Text,
		TextSize = 15,
	})
	closeBtn.MouseButton1Click:Connect(function()
		overlay.Visible = false
	end)
	return overlay, panel
end

local function formatPlaytime(seconds: number): string
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	if h > 0 then
		return ("%dh %dm %ds"):format(h, m, s)
	end
	return ("%dm %ds"):format(m, s)
end

function Extras.Start()
	local rebirthFn = ReplicatedStorage:WaitForChild("Rebirth") :: RemoteFunction
	local redeemFn = ReplicatedStorage:WaitForChild("RedeemCode") :: RemoteFunction

	local gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerExtras"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.Parent = player:WaitForChild("PlayerGui")

	-- ============== Rebirth (button always visible) ==============
	local function fmt(n: number): string
		if n >= 1e6 then
			return string.format("%.1fM", n / 1e6)
		elseif n >= 1e3 then
			return string.format("%.0fK", n / 1e3)
		end
		return tostring(math.floor(n))
	end

	local rebirthBtn = button(gui, "", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0, 280, 0, 52),
		BackgroundColor3 = C.PinkDark,
	})
	label(rebirthBtn, {
		Position = UDim2.new(0, 0, 0, 5),
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🐾 REBIRTH",
	})
	local rebirthProgress = label(rebirthBtn, {
		Position = UDim2.new(0, 0, 0, 29),
		Size = UDim2.new(1, 0, 0, 18),
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 232, 210),
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "",
	})

	local rebirthOverlay, rebirthPanel = modal(gui, "🐾 Rebirth", 300)
	local pointsLine = label(rebirthPanel, {
		Position = UDim2.new(0, 20, 0, 46),
		Size = UDim2.new(1, -40, 0, 24),
		TextSize = 17,
		TextColor3 = C.PinkDark,
		Text = "",
	})
	label(rebirthPanel, {
		Position = UDim2.new(0, 20, 0, 74),
		Size = UDim2.new(1, -40, 0, 36),
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = C.TextSoft,
		Text = ("Each Cat Point = +%d%% ALL treats forever, plus %d Paw Coins for eggs. Your cats and upgrades stay!"):format(
			Config.Prestige.BoostPerPoint * 100, Config.Prestige.CoinsPerPoint),
	})

	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.new(0, 20, 0, 122)
	barBack.Size = UDim2.new(1, -40, 0, 20)
	barBack.BackgroundColor3 = C.Background
	barBack.BorderSizePixel = 0
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBack
	barBack.Parent = rebirthPanel
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = C.Accent
	barFill.BorderSizePixel = 0
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill
	barFill.Parent = barBack

	local progressLine = label(rebirthPanel, {
		Position = UDim2.new(0, 20, 0, 146),
		Size = UDim2.new(1, -40, 0, 20),
		TextSize = 13,
		Text = "",
	})
	local gainLine = label(rebirthPanel, {
		Position = UDim2.new(0, 20, 0, 172),
		Size = UDim2.new(1, -40, 0, 24),
		TextSize = 16,
		Text = "",
	})
	local goBtn = button(rebirthPanel, "REBIRTH NOW!", {
		Position = UDim2.new(0, 20, 1, -60),
		Size = UDim2.new(1, -40, 0, 44),
		BackgroundColor3 = C.PinkDark,
		TextSize = 18,
	})

	local treatsNow = 0
	local function updateRebirth()
		local threshold = Config.Prestige.Threshold
		local points = math.floor(treatsNow / threshold)
		local catPoints = (player:GetAttribute("CatPoints") :: number?) or 0

		rebirthProgress.Text = points >= 1
			and ("READY!  +%d Cat Point%s"):format(points, points == 1 and "" or "s")
			or ("%s / %s treats"):format(fmt(treatsNow), fmt(threshold))
		rebirthBtn.BackgroundColor3 = points >= 1 and C.PinkDark or C.PanelShadow

		pointsLine.Text = ("Cat Points: %d   (+%d%% all treats)"):format(
			catPoints, catPoints * Config.Prestige.BoostPerPoint * 100)
		local frac = math.clamp((treatsNow % threshold) / threshold, 0, 1)
		barFill.Size = UDim2.new(points >= 1 and 1 or frac, 0, 1, 0)
		progressLine.Text = ("%s / %s treats toward the next point"):format(fmt(treatsNow), fmt(threshold))
		if points >= 1 then
			gainLine.Text = ("Rebirth now:  +%d Cat Points,  +%d 🪙"):format(
				points, points * Config.Prestige.CoinsPerPoint)
			gainLine.TextColor3 = Color3.fromRGB(90, 170, 100)
			goBtn.BackgroundColor3 = C.PinkDark
			goBtn.Text = "REBIRTH NOW!"
		else
			gainLine.Text = "Keep clicking — you're not there yet!"
			gainLine.TextColor3 = C.TextSoft
			goBtn.BackgroundColor3 = C.PanelShadow
			goBtn.Text = ("NEED %s MORE TREATS"):format(fmt(Config.Prestige.Threshold - treatsNow))
		end
	end

	rebirthBtn.MouseButton1Click:Connect(function()
		updateRebirth()
		rebirthOverlay.Visible = true
	end)

	goBtn.MouseButton1Click:Connect(function()
		local ok = rebirthFn:InvokeServer()
		if ok then
			rebirthOverlay.Visible = false
			local flash = Instance.new("Frame")
			flash.Size = UDim2.fromScale(1, 1)
			flash.BackgroundColor3 = C.Accent
			flash.BackgroundTransparency = 0.2
			flash.Parent = gui
			game:GetService("TweenService"):Create(flash,
				TweenInfo.new(0.9, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
			task.delay(1, function()
				flash:Destroy()
			end)
		end
	end)

	-- ============== Codes panel ==============
	local codesOverlay, codesPanel = modal(gui, "🎁 Codes", 190)
	local codeBox = Instance.new("TextBox")
	codeBox.Position = UDim2.new(0, 20, 0, 52)
	codeBox.Size = UDim2.new(1, -40, 0, 40)
	codeBox.BackgroundColor3 = C.Background
	codeBox.BorderSizePixel = 0
	codeBox.Font = Enum.Font.FredokaOne
	codeBox.PlaceholderText = "enter code..."
	codeBox.Text = ""
	codeBox.TextSize = 18
	codeBox.TextColor3 = C.Text
	codeBox.ClearTextOnFocus = false
	round(codeBox, 10)
	codeBox.Parent = codesPanel

	local resultLabel = label(codesPanel, {
		Position = UDim2.new(0, 20, 0, 96),
		Size = UDim2.new(1, -40, 0, 22),
		TextSize = 14,
		TextColor3 = C.TextSoft,
		Text = "",
	})
	local redeemBtn = button(codesPanel, "REDEEM", {
		Position = UDim2.new(0, 20, 1, -56),
		Size = UDim2.new(1, -40, 0, 40),
	})
	redeemBtn.MouseButton1Click:Connect(function()
		if codeBox.Text == "" then
			return
		end
		local ok, message = redeemFn:InvokeServer(codeBox.Text)
		resultLabel.Text = tostring(message)
		resultLabel.TextColor3 = ok and Color3.fromRGB(90, 170, 100) or Color3.fromRGB(220, 90, 90)
		if ok then
			codeBox.Text = ""
		end
	end)

	-- ============== Settings panel ==============
	local infoOverlay, infoPanel = modal(gui, "⚙️ Settings", 260)
	local playtimeLabel = label(infoPanel, {
		Position = UDim2.new(0, 20, 0, 52),
		Size = UDim2.new(1, -40, 0, 24),
		TextSize = 16,
		Text = "Playtime: 0m 0s",
	})
	label(infoPanel, {
		Position = UDim2.new(0, 20, 0, 84),
		Size = UDim2.new(1, -40, 0, 56),
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = C.PinkDark,
		Text = "💜 Join our Roblox group for +10% Treats!\n(group link coming soon)",
	})

	-- Reset Save (testing) with its own confirmation
	local resetBtn = button(infoPanel, "🗑️ RESET SAVE", {
		Position = UDim2.new(0, 20, 1, -56),
		Size = UDim2.new(1, -40, 0, 40),
		BackgroundColor3 = Color3.fromRGB(226, 96, 96),
	})

	local resetOverlay, resetPanel = modal(gui, "🗑️ Reset Save?", 170)
	label(resetPanel, {
		Position = UDim2.new(0, 20, 0, 44),
		Size = UDim2.new(1, -40, 0, 56),
		TextSize = 15,
		TextWrapped = true,
		Text = "This deletes ALL progress — treats, cats, upgrades, Cat Points and codes. Are you sure?",
	})
	local resetYes = button(resetPanel, "DELETE IT ALL", {
		Position = UDim2.new(0, 20, 1, -56),
		Size = UDim2.new(0.5, -30, 0, 40),
		BackgroundColor3 = Color3.fromRGB(226, 96, 96),
	})
	local resetNo = button(resetPanel, "Keep it!", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 1, -56),
		Size = UDim2.new(0.5, -30, 0, 40),
		BackgroundColor3 = C.Background,
		TextColor3 = C.Text,
	})

	resetBtn.MouseButton1Click:Connect(function()
		infoOverlay.Visible = false
		resetOverlay.Visible = true
	end)
	resetNo.MouseButton1Click:Connect(function()
		resetOverlay.Visible = false
	end)
	resetYes.MouseButton1Click:Connect(function()
		resetOverlay.Visible = false
		local resetFn = ReplicatedStorage:WaitForChild("ResetSave") :: RemoteFunction
		resetFn:InvokeServer()
	end)
	task.spawn(function()
		while true do
			if infoOverlay.Visible then
				local base = (player:GetAttribute("PlaytimeBase") :: number?) or 0
				playtimeLabel.Text = "Playtime: " .. formatPlaytime(base + (os.clock() - sessionStart))
			end
			task.wait(1)
		end
	end)

	-- ============== Corner buttons ==============
	local codesBtn = button(gui, "🎁", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, -190, 1, -14),
		Size = UDim2.new(0, 46, 0, 46),
		TextSize = 22,
	})
	round(codesBtn, 0)
	codesBtn.MouseButton1Click:Connect(function()
		codesOverlay.Visible = not codesOverlay.Visible
	end)

	local infoBtn = button(gui, "⚙️", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 190, 1, -14),
		Size = UDim2.new(0, 46, 0, 46),
		BackgroundColor3 = C.PanelShadow,
		TextSize = 22,
	})
	round(infoBtn, 0)
	infoBtn.MouseButton1Click:Connect(function()
		infoOverlay.Visible = not infoOverlay.Visible
	end)

	-- ============== Offline earnings popup ==============
	local offlineNotify = ReplicatedStorage:WaitForChild("OfflineEarnings") :: RemoteEvent
	local offlineOverlay, offlinePanel = modal(gui, "😴 Welcome back!", 180)
	local offlineText = label(offlinePanel, {
		Position = UDim2.new(0, 20, 0, 48),
		Size = UDim2.new(1, -40, 0, 66),
		TextSize = 16,
		TextWrapped = true,
		Text = "",
	})
	local offlineOk = button(offlinePanel, "NICE! 🐾", {
		Position = UDim2.new(0, 20, 1, -56),
		Size = UDim2.new(1, -40, 0, 40),
	})
	offlineOk.MouseButton1Click:Connect(function()
		offlineOverlay.Visible = false
	end)
	offlineNotify.OnClientEvent:Connect(function(amount, minutes)
		if type(amount) == "number" and type(minutes) == "number" then
			offlineText.Text = ("Your cats kept working while you were away!\n\n+%s treats earned over %d minute%s"):format(
				tostring(amount), minutes, minutes == 1 and "" or "s")
			offlineOverlay.Visible = true
		end
	end)

	-- ============== Auto-save indicator ==============
	local savedNotify = ReplicatedStorage:WaitForChild("SavedNotify") :: RemoteEvent
	local savedLabel = label(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -66),
		Size = UDim2.new(0, 200, 0, 24),
		TextSize = 16,
		TextColor3 = Color3.fromRGB(90, 170, 100),
		TextTransparency = 1,
		Text = "💾 Saved!",
	})
	savedNotify.OnClientEvent:Connect(function()
		local TweenService = game:GetService("TweenService")
		savedLabel.TextTransparency = 0
		task.delay(1.4, function()
			TweenService:Create(savedLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		end)
	end)

	-- ============== Rebirth progress wiring ==============
	task.spawn(function()
		local stats = player:WaitForChild("leaderstats")
		local treats = stats:WaitForChild("Treats") :: NumberValue
		treats.Changed:Connect(function()
			treatsNow = treats.Value
			updateRebirth()
		end)
		player:GetAttributeChangedSignal("CatPoints"):Connect(updateRebirth)
		treatsNow = treats.Value
		updateRebirth()
	end)
end

return Extras

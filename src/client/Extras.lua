--!strict
-- Rebirth button (with confirm popup), redeemable codes panel, and a
-- settings/info panel with playtime + group placeholder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Extras = {}

local player = Players.LocalPlayer
local C = Config.Colors
local sessionStart = os.clock()

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

	-- ============== Rebirth button + confirm ==============
	local rebirthBtn = button(gui, "", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0, 280, 0, 46),
		BackgroundColor3 = C.PinkDark,
		Visible = false,
	})

	local confirmOverlay, confirmPanel = modal(gui, "🐾 Rebirth?", 170)
	local confirmText = label(confirmPanel, {
		Position = UDim2.new(0, 20, 0, 44),
		Size = UDim2.new(1, -40, 0, 56),
		TextSize = 15,
		TextWrapped = true,
		Text = "",
	})
	local yesBtn = button(confirmPanel, "REBIRTH!", {
		Position = UDim2.new(0, 20, 1, -56),
		Size = UDim2.new(0.5, -30, 0, 40),
		BackgroundColor3 = C.PinkDark,
	})
	local noBtn = button(confirmPanel, "Not yet", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 1, -56),
		Size = UDim2.new(0.5, -30, 0, 40),
		BackgroundColor3 = C.Background,
		TextColor3 = C.Text,
	})
	noBtn.MouseButton1Click:Connect(function()
		confirmOverlay.Visible = false
	end)

	local pendingPoints = 0
	rebirthBtn.MouseButton1Click:Connect(function()
		confirmText.Text = ("Reset your Treats to 0 for %d Cat Point%s? Each gives a permanent +%d%% treats/sec. Your cats and upgrades stay!"):format(
			pendingPoints, pendingPoints == 1 and "" or "s",
			Config.Prestige.BoostPerPoint * 100)
		confirmOverlay.Visible = true
	end)
	yesBtn.MouseButton1Click:Connect(function()
		confirmOverlay.Visible = false
		local ok, result = rebirthFn:InvokeServer()
		if ok then
			-- Celebration flash
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

	-- ============== Info panel ==============
	local infoOverlay, infoPanel = modal(gui, "⚙️ Info", 190)
	local playtimeLabel = label(infoPanel, {
		Position = UDim2.new(0, 20, 0, 52),
		Size = UDim2.new(1, -40, 0, 24),
		TextSize = 16,
		Text = "Playtime: 0m 0s",
	})
	label(infoPanel, {
		Position = UDim2.new(0, 20, 0, 88),
		Size = UDim2.new(1, -40, 0, 60),
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = C.PinkDark,
		Text = "💜 Join our Roblox group for +10% Treats!\n(group link coming soon)",
	})
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

	-- ============== Rebirth button visibility ==============
	task.spawn(function()
		local stats = player:WaitForChild("leaderstats")
		local treats = stats:WaitForChild("Treats") :: NumberValue
		local function update()
			local points = math.floor(treats.Value / Config.Prestige.Threshold)
			pendingPoints = points
			rebirthBtn.Visible = points >= 1
			if points >= 1 then
				rebirthBtn.Text = ("🐾 REBIRTH: +%d Cat Point%s"):format(points, points == 1 and "" or "s")
			end
		end
		treats.Changed:Connect(update)
		update()
	end)
end

return Extras

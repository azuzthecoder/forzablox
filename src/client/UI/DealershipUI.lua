--!strict
-- Dealership browser: car list with stats, buy and spawn actions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CarCatalog = require(Shared:WaitForChild("CarCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(script.Parent.Theme)
local ClientState = require(script.Parent.Parent.ClientState)
local Notifications = require(script.Parent.Notifications)

local DealershipUI = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local selectedId: string? = nil

local detailName: TextLabel
local detailMeta: TextLabel
local detailDesc: TextLabel
local detailPrice: TextLabel
local actionButton: TextButton
local creditsLabel: TextLabel
local statBars: { [string]: Frame } = {}
local cardButtons: { [string]: TextButton } = {}

local STATS = {
	{ key = "Speed", get = function(c) return c.topSpeedMph / 290 end },
	{ key = "Power", get = function(c) return c.power / 110 end },
	{ key = "Grip", get = function(c) return (c.grip - 0.8) / 0.9 end },
	{ key = "Brake", get = function(c) return c.brake / 135 end },
}

local function refresh()
	creditsLabel.Text = Theme.FormatCredits(ClientState.Profile.credits)
	for id, button in cardButtons do
		local def = CarCatalog.Get(id)
		if def then
			button.Text = ClientState.Owns(id) and "  OWNED  •  " .. def.name
				or "  " .. Theme.FormatCredits(def.price) .. "  •  " .. def.name
			button.TextColor3 = ClientState.Owns(id) and Theme.Colors.Good or Theme.Colors.Text
		end
	end

	local def = selectedId and CarCatalog.Get(selectedId :: string)
	if not def then
		return
	end
	detailName.Text = def.name
	detailMeta.Text = def.brand .. "  •  CLASS " .. def.class .. "  •  " .. def.drive
	detailMeta.TextColor3 = CarCatalog.ClassColors[def.class] or Theme.Colors.Accent2
	detailDesc.Text = def.description
	detailPrice.Text = Theme.FormatCredits(def.price)
	for _, stat in STATS do
		statBars[stat.key].Size = UDim2.new(math.clamp(stat.get(def), 0.05, 1), 0, 1, 0)
	end
	if ClientState.Owns(def.id) then
		actionButton.Text = "SPAWN"
		actionButton.BackgroundColor3 = Theme.Colors.Accent2
		actionButton.TextColor3 = Color3.fromRGB(10, 20, 30)
	else
		actionButton.Text = "BUY"
		actionButton.BackgroundColor3 = ClientState.Profile.credits >= def.price
			and Theme.Colors.Accent or Theme.Colors.PanelLight
		actionButton.TextColor3 = Theme.Colors.Text
	end
end

local function select(id: string)
	selectedId = id
	refresh()
end

local function onAction()
	local def = selectedId and CarCatalog.Get(selectedId :: string)
	if not def then
		return
	end
	if ClientState.Owns(def.id) then
		(Remotes.Get("SpawnCar") :: RemoteEvent):FireServer(def.id)
		gui.Enabled = false
	else
		local ok, message = (Remotes.Get("BuyCar") :: RemoteFunction):InvokeServer(def.id)
		Notifications.Push(tostring(message), ok and "success" or "error")
	end
end

function DealershipUI.Start()
	gui = Instance.new("ScreenGui")
	gui.Name = "ForzaBloxDealership"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local backdrop = Instance.new("TextButton") -- click-through blocker
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.45
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = gui

	local panel = Theme.Panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 860, 0, 520),
	})
	Theme.Stroke(panel, Theme.Colors.Accent, 2, 0.3)

	Theme.Label(panel, {
		Position = UDim2.new(0, 20, 0, 12),
		Size = UDim2.new(0, 500, 0, 30),
		Font = Theme.FontHeavy, TextSize = 24,
		Text = "FORZABLOX AUTOSHOW",
	})
	creditsLabel = Theme.Label(panel, {
		Position = UDim2.new(1, -260, 0, 12),
		Size = UDim2.new(0, 190, 0, 30),
		Font = Theme.FontHeavy, TextSize = 18,
		TextColor3 = Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "0 CR",
	})
	local close = Theme.Button(panel, "X", {
		Position = UDim2.new(1, -50, 0, 12),
		Size = UDim2.new(0, 34, 0, 30),
		BackgroundColor3 = Theme.Colors.PanelLight,
	})
	close.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	-- Car list (left)
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 20, 0, 56)
	list.Size = UDim2.new(0, 380, 1, -76)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 5
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local sorted = table.clone(CarCatalog.Cars)
	table.sort(sorted, function(a, b)
		return a.price < b.price
	end)
	for order, def in sorted do
		local card = Theme.Button(list, "", {
			Size = UDim2.new(1, -8, 0, 44),
			BackgroundColor3 = Theme.Colors.PanelLight,
			Font = Theme.FontBold, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = order,
		})
		local chip = Instance.new("Frame")
		chip.AnchorPoint = Vector2.new(1, 0.5)
		chip.Position = UDim2.new(1, -10, 0.5, 0)
		chip.Size = UDim2.new(0, 30, 0, 20)
		chip.BackgroundColor3 = CarCatalog.ClassColors[def.class] or Theme.Colors.Accent2
		Theme.Corner(chip, 4)
		chip.Parent = card
		local chipText = Theme.Label(chip, {
			Size = UDim2.fromScale(1, 1),
			Font = Theme.FontHeavy, TextSize = 12,
			TextColor3 = Color3.fromRGB(15, 15, 20),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = def.class,
		})
		chipText.Parent = chip
		cardButtons[def.id] = card
		card.MouseButton1Click:Connect(function()
			select(def.id)
		end)
	end

	-- Details (right)
	local details = Theme.Panel(panel, {
		Position = UDim2.new(0, 416, 0, 56),
		Size = UDim2.new(1, -436, 1, -76),
		BackgroundColor3 = Theme.Colors.Background,
	})
	detailName = Theme.Label(details, {
		Position = UDim2.new(0, 18, 0, 14),
		Size = UDim2.new(1, -36, 0, 30),
		Font = Theme.FontHeavy, TextSize = 26, Text = "",
	})
	detailMeta = Theme.Label(details, {
		Position = UDim2.new(0, 18, 0, 46),
		Size = UDim2.new(1, -36, 0, 20),
		Font = Theme.FontBold, TextSize = 14, Text = "",
	})
	detailDesc = Theme.Label(details, {
		Position = UDim2.new(0, 18, 0, 72),
		Size = UDim2.new(1, -36, 0, 54),
		Font = Theme.Font, TextSize = 14,
		TextColor3 = Theme.Colors.SubText,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
	})
	for i, stat in STATS do
		Theme.Label(details, {
			Position = UDim2.new(0, 18, 0, 128 + (i - 1) * 34),
			Size = UDim2.new(0, 60, 0, 16),
			Font = Theme.FontBold, TextSize = 13,
			TextColor3 = Theme.Colors.SubText, Text = stat.key:upper(),
		})
		local track = Instance.new("Frame")
		track.Position = UDim2.new(0, 88, 0, 130 + (i - 1) * 34)
		track.Size = UDim2.new(1, -110, 0, 12)
		track.BackgroundColor3 = Theme.Colors.PanelLight
		track.BorderSizePixel = 0
		Theme.Corner(track, 6)
		track.Parent = details
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0.5, 0, 1, 0)
		fill.BorderSizePixel = 0
		fill.BackgroundColor3 = Theme.Colors.Accent2
		Theme.Corner(fill, 6)
		Theme.Gradient(fill, Theme.Colors.Accent2, Theme.Colors.Accent)
		fill.Parent = track
		statBars[stat.key] = fill
	end
	detailPrice = Theme.Label(details, {
		Position = UDim2.new(0, 18, 1, -92),
		Size = UDim2.new(1, -36, 0, 26),
		Font = Theme.FontHeavy, TextSize = 22,
		TextColor3 = Theme.Colors.Gold, Text = "",
	})
	actionButton = Theme.Button(details, "BUY", {
		Position = UDim2.new(0, 18, 1, -58),
		Size = UDim2.new(1, -36, 0, 42),
		TextSize = 18,
	})
	actionButton.MouseButton1Click:Connect(onAction)

	select(sorted[1].id)
	ClientState.ProfileChanged.Event:Connect(refresh)

	local open = Remotes.Get("OpenDealership") :: RemoteEvent
	open.OnClientEvent:Connect(function()
		refresh()
		gui.Enabled = true
	end)
end

return DealershipUI

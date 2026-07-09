--!strict
-- Stage 2: the upgrade shop sidebar. Cards for each generator with icon,
-- name, rate, live cost and owned count; unaffordable ones are grayed out.
-- Also shows the Treats/sec readout under the main counter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Shop = {}

local player = Players.LocalPlayer
local C = Config.Colors

local counts: { [string]: number } = {}
local clickUpgrades: { [string]: boolean } = {}
local treatsValue: NumberValue? = nil
local discountUntil = 0 -- Money Cat: 50% off while os.clock() < this

local function priceOf(cost: number): (number, boolean)
	if os.clock() < discountUntil then
		return math.floor(cost * 0.5), true
	end
	return cost, false
end

type UpgradeCard = {
	button: TextButton,
	costLabel: TextLabel,
	upgrade: any,
}
local upgradeCards: { UpgradeCard } = {}

type Card = {
	button: TextButton,
	costLabel: TextLabel,
	ownedLabel: TextLabel,
	icon: TextLabel,
	gen: any,
}
local cards: { Card } = {}
local tpsLabel: TextLabel

-- ============================ HELPERS ============================

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

local function formatRate(rate: number): string
	if rate < 1 then
		return string.format("%.1f", rate)
	end
	return formatNumber(rate)
end

-- ============================ REFRESH ============================

local function refresh()
	local treats = treatsValue and treatsValue.Value or 0

	local perSecond = 0
	for _, gen in Config.Generators do
		perSecond += gen.rate * (counts[gen.id] or 0)
	end
	tpsLabel.Text = "per second: " .. formatRate(perSecond)
		.. "   •   per click: " .. formatNumber(Config.ClickAmount(clickUpgrades))

	for _, card in upgradeCards do
		local owned = clickUpgrades[card.upgrade.id] == true
		card.button.Visible = not owned
		if not owned then
			local cost, discounted = priceOf(card.upgrade.cost)
			local affordable = treats >= cost
			card.costLabel.Text = "🍪 " .. formatNumber(cost) .. (discounted and "  (50% OFF!)" or "")
			card.costLabel.TextColor3 = discounted and Color3.fromRGB(90, 170, 100)
				or (affordable and C.PinkDark or C.TextSoft)
			card.button.BackgroundColor3 = affordable and C.Panel or C.Background
			card.button.AutoButtonColor = affordable
		end
	end

	for _, card in cards do
		local owned = counts[card.gen.id] or 0
		local cost, discounted = priceOf(Config.CostFor(card.gen, owned))
		local affordable = treats >= cost

		card.costLabel.Text = "🍪 " .. formatNumber(cost) .. (discounted and "  (50% OFF!)" or "")
		card.ownedLabel.Text = tostring(owned)
		card.costLabel.TextColor3 = discounted and Color3.fromRGB(90, 170, 100)
			or (affordable and C.PinkDark or C.TextSoft)
		card.button.BackgroundColor3 = affordable and C.Panel or C.Background
		card.button.AutoButtonColor = affordable
		card.icon.TextTransparency = affordable and 0 or 0.45
	end
end

-- ============================ BUILD ============================

function Shop.Start()
	local buyEvent = ReplicatedStorage:WaitForChild("BuyGenerator") :: RemoteEvent
	local shopSync = ReplicatedStorage:WaitForChild("ShopSync") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerShop"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Treats/sec readout (sits under the big counter from stage 1)
	tpsLabel = label(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.new(0, 400, 0, 24),
		TextSize = 20,
		TextColor3 = C.PinkDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "per second: 0",
	})

	-- Sidebar
	local sidebar = Instance.new("Frame")
	sidebar.AnchorPoint = Vector2.new(1, 0)
	sidebar.Position = UDim2.new(1, -12, 0, 12)
	sidebar.Size = UDim2.new(0, 320, 1, -24)
	sidebar.BackgroundColor3 = C.Panel
	sidebar.BackgroundTransparency = 0.06
	sidebar.BorderSizePixel = 0
	round(sidebar, 18)
	sidebar.Parent = gui

	label(sidebar, {
		Position = UDim2.new(0, 18, 0, 12),
		Size = UDim2.new(1, -36, 0, 30),
		TextSize = 24,
		TextColor3 = C.PinkDark,
		Text = "🛍️ Cat Shop",
	})

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 10, 0, 50)
	list.Size = UDim2.new(1, -20, 1, -60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 5
	list.ScrollBarImageColor3 = C.Pink
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = sidebar

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	-- ============== Click upgrades section (Stage 3) ==============
	local buyUpgrade = ReplicatedStorage:WaitForChild("BuyClickUpgrade") :: RemoteEvent

	label(list, {
		Size = UDim2.new(1, -8, 0, 24),
		TextSize = 17,
		TextColor3 = C.TextSoft,
		Text = "⚡ Click Upgrades",
		LayoutOrder = 1,
	})

	for i, upgrade in Config.ClickUpgrades do
		local card = Instance.new("TextButton")
		card.Size = UDim2.new(1, -8, 0, 54)
		card.BackgroundColor3 = C.Panel
		card.BorderSizePixel = 0
		card.Text = ""
		card.LayoutOrder = 1 + i
		round(card, 12)
		card.Parent = list

		local stroke = Instance.new("UIStroke")
		stroke.Color = C.PanelShadow
		stroke.Thickness = 2
		stroke.Parent = card

		label(card, {
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(0, 32, 1, 0),
			TextSize = 24,
			Text = upgrade.icon,
		})
		label(card, {
			Position = UDim2.new(0, 50, 0, 7),
			Size = UDim2.new(1, -60, 0, 20),
			TextSize = 16,
			Text = upgrade.name .. ((upgrade :: any).mult
				and ("  (x" .. (upgrade :: any).mult .. " click)")
				or ("  (+" .. (upgrade :: any).add .. " click)")),
		})
		local costLabel = label(card, {
			Position = UDim2.new(0, 50, 0, 28),
			Size = UDim2.new(1, -60, 0, 18),
			TextSize = 14,
			TextColor3 = C.PinkDark,
			Text = "🍪 " .. formatNumber(upgrade.cost),
		})

		card.MouseButton1Click:Connect(function()
			buyUpgrade:FireServer(upgrade.id)
		end)

		table.insert(upgradeCards, { button = card, costLabel = costLabel, upgrade = upgrade })
	end

	-- ============== Generators section (Stage 2) ==============
	label(list, {
		Size = UDim2.new(1, -8, 0, 24),
		TextSize = 17,
		TextColor3 = C.TextSoft,
		Text = "🐱 Cats (per second)",
		LayoutOrder = 50,
	})

	for order, gen in Config.Generators do
		local card = Instance.new("TextButton")
		card.Size = UDim2.new(1, -8, 0, 76)
		card.BackgroundColor3 = C.Panel
		card.BorderSizePixel = 0
		card.Text = ""
		card.LayoutOrder = 50 + order
		round(card, 14)
		card.Parent = list

		local stroke = Instance.new("UIStroke")
		stroke.Color = C.PanelShadow
		stroke.Thickness = 2
		stroke.Parent = card

		local iconBg = Instance.new("Frame")
		iconBg.Position = UDim2.new(0, 10, 0.5, -24)
		iconBg.Size = UDim2.new(0, 48, 0, 48)
		iconBg.BackgroundColor3 = C.Background
		iconBg.BorderSizePixel = 0
		round(iconBg, 0)
		iconBg.Parent = card

		local icon = label(iconBg, {
			Size = UDim2.fromScale(1, 1),
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = gen.icon,
		})

		label(card, {
			Position = UDim2.new(0, 68, 0, 10),
			Size = UDim2.new(1, -130, 0, 22),
			TextSize = 18,
			Text = gen.name,
		})
		label(card, {
			Position = UDim2.new(0, 68, 0, 32),
			Size = UDim2.new(1, -130, 0, 16),
			TextSize = 13,
			TextColor3 = C.TextSoft,
			Text = "+" .. formatRate(gen.rate) .. " treats/sec",
		})
		local costLabel = label(card, {
			Position = UDim2.new(0, 68, 0, 50),
			Size = UDim2.new(1, -130, 0, 18),
			TextSize = 15,
			TextColor3 = C.PinkDark,
			Text = "",
		})
		local ownedLabel = label(card, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(0, 50, 0, 40),
			TextSize = 30,
			TextColor3 = C.PanelShadow,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "0",
		})

		card.MouseButton1Click:Connect(function()
			buyEvent:FireServer(gen.id)
		end)

		table.insert(cards, { button = card, costLabel = costLabel, ownedLabel = ownedLabel, icon = icon, gen = gen })
	end

	-- ============================ SYNC ============================

	shopSync.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" then
			counts = payload.counts or {}
			clickUpgrades = payload.clickUpgrades or {}
			refresh()
		end
	end)
	shopSync:FireServer() -- request initial state

	-- Money Cat discount: retint prices while active
	local boostSync = ReplicatedStorage:WaitForChild("BoostSync") :: RemoteEvent
	boostSync.OnClientEvent:Connect(function(kind, _typeId, _magnitude, duration)
		if kind == "discount" and type(duration) == "number" then
			discountUntil = os.clock() + duration
			refresh()
			task.spawn(function()
				while os.clock() < discountUntil do
					task.wait(1)
				end
				refresh() -- prices back to normal
			end)
		end
	end)

	task.spawn(function()
		local stats = player:WaitForChild("leaderstats")
		treatsValue = stats:WaitForChild("Treats") :: NumberValue
		(treatsValue :: NumberValue).Changed:Connect(refresh)
		refresh()
	end)
end

return Shop

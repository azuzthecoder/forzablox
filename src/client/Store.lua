--!strict
-- Robux store: VIP gamepass + developer products (treats, coins, rebirths,
-- boosts). Purchases are prompted here and granted server-side via
-- ProcessReceipt. Product/pass ids live in Config.Monetization.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Store = {}

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
	b.TextSize = 15
	for key, value in props do
		(b :: any)[key] = value
	end
	round(b, 10)
	b.Parent = parent
	return b
end

function Store.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerStore"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 25
	gui.Parent = player:WaitForChild("PlayerGui")

	local toggle = button(gui, "💎", {
		Position = UDim2.new(0, 12, 0, 462),
		Size = UDim2.new(0, 46, 0, 46),
		TextSize = 22,
		BackgroundColor3 = Color3.fromRGB(120, 190, 255),
	})
	round(toggle, 0)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 480, 0, 440)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	round(panel, 18)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 190, 255)
	stroke.Thickness = 2
	stroke.Parent = panel
	panel.Parent = gui

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	label(panel, {
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 0, 28),
		TextSize = 22,
		TextColor3 = C.PinkDark,
		Text = "💎 Cat Store",
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

	local note = label(panel, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -40, 0, 20),
		TextSize = 12,
		TextColor3 = C.TextSoft,
		Text = "",
	})

	-- ============== VIP card ==============
	local vipCard = Instance.new("Frame")
	vipCard.Position = UDim2.new(0, 16, 0, 50)
	vipCard.Size = UDim2.new(1, -32, 0, 76)
	vipCard.BackgroundColor3 = Color3.fromRGB(255, 236, 180)
	vipCard.BorderSizePixel = 0
	round(vipCard, 14)
	vipCard.Parent = panel

	label(vipCard, {
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -140, 0, 26),
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "👑 VIP — x" .. Config.Monetization.VipMultiplier .. " ALL treats forever",
	})
	label(vipCard, {
		Position = UDim2.new(0, 16, 0, 38),
		Size = UDim2.new(1, -140, 0, 20),
		TextSize = 13,
		TextColor3 = C.TextSoft,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Permanent gamepass. Stacks with everything!",
	})
	local vipBtn = button(vipCard, "GET VIP", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 110, 0, 40),
		BackgroundColor3 = Color3.fromRGB(240, 170, 40),
	})

	local function refreshVip()
		if player:GetAttribute("VIP") then
			vipBtn.Text = "✓ OWNED"
			vipBtn.BackgroundColor3 = C.PanelShadow
		end
	end
	player:GetAttributeChangedSignal("VIP"):Connect(refreshVip)
	refreshVip()

	vipBtn.MouseButton1Click:Connect(function()
		if Config.Monetization.VipGamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.Monetization.VipGamePassId)
		else
			note.Text = "Set VipGamePassId in Config.lua first (see setup guide)!"
		end
	end)

	-- ============== Product grid ==============
	for i, product in Config.Monetization.Products do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		local card = Instance.new("Frame")
		card.Position = UDim2.new(0, 16 + col * 228, 0, 140 + row * 88)
		card.Size = UDim2.new(0, 220, 0, 80)
		card.BackgroundColor3 = C.Background
		card.BorderSizePixel = 0
		round(card, 12)
		card.Parent = panel

		label(card, {
			Position = UDim2.new(0, 10, 0, 8),
			Size = UDim2.new(0, 40, 0, 36),
			TextSize = 26,
			Text = product.icon,
		})
		label(card, {
			Position = UDim2.new(0, 54, 0, 10),
			Size = UDim2.new(1, -64, 0, 22),
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = product.name,
		})
		local buyBtn = button(card, "BUY  R$", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 30),
			TextSize = 13,
			BackgroundColor3 = Color3.fromRGB(90, 200, 120),
		})
		buyBtn.MouseButton1Click:Connect(function()
			if product.id > 0 then
				MarketplaceService:PromptProductPurchase(player, product.id)
			else
				note.Text = "Set this product's id in Config.lua first (see setup guide)!"
			end
		end)
	end
end

return Store

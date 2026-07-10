--!strict
-- Robux store: VIP gamepass + developer products (treats, coins, rebirths,
-- boosts). Purchases are prompted here and granted server-side via
-- ProcessReceipt. Product/pass ids live in Config.Monetization.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
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
	panel.Size = UDim2.new(0, 480, 0, 470)
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
	vipCard.Size = UDim2.new(1, -32, 0, 96)
	vipCard.BackgroundColor3 = Color3.fromRGB(255, 236, 180)
	vipCard.BorderSizePixel = 0
	round(vipCard, 14)
	local vipGradient = Instance.new("UIGradient")
	vipGradient.Color = ColorSequence.new(Color3.fromRGB(255, 244, 205), Color3.fromRGB(255, 216, 140))
	vipGradient.Rotation = 25
	vipGradient.Parent = vipCard
	vipCard.Parent = panel

	label(vipCard, {
		Position = UDim2.new(0, 16, 0, 8),
		Size = UDim2.new(1, -140, 0, 26),
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "👑 VIP — x" .. Config.Monetization.VipMultiplier .. " ALL treats forever",
	})
	label(vipCard, {
		Position = UDim2.new(0, 16, 0, 36),
		Size = UDim2.new(1, -140, 0, 52),
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = "• x" .. Config.Monetization.VipCoinMultiplier .. " Paw Coins from rebirths, check-ins & spins\n"
			.. "• FULL treats while offline (everyone else gets 50%)\n"
			.. "• Stacks with pets, boosts and rebirths!",
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
		card.Position = UDim2.new(0, 16 + col * 228, 0, 160 + row * 88)
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

	-- ============================================================
	-- FLOATING PROMOS: eye-candy that bobs around the screen and
	-- opens purchases with one tap.
	-- ============================================================

	-- 👑 VIP badge (hides once owned)
	local vipPromo = Instance.new("TextButton")
	vipPromo.Position = UDim2.new(0, 274, 0, 16)
	vipPromo.Size = UDim2.new(0, 170, 0, 66)
	vipPromo.BackgroundColor3 = Color3.fromRGB(255, 224, 150)
	vipPromo.BorderSizePixel = 0
	vipPromo.Text = ""
	round(vipPromo, 16)
	local promoGradient = Instance.new("UIGradient")
	promoGradient.Color = ColorSequence.new(Color3.fromRGB(255, 246, 215), Color3.fromRGB(255, 205, 110))
	promoGradient.Rotation = 30
	promoGradient.Parent = vipPromo
	local promoStroke = Instance.new("UIStroke")
	promoStroke.Color = Color3.fromRGB(240, 170, 40)
	promoStroke.Thickness = 2.5
	promoStroke.Parent = vipPromo
	label(vipPromo, {
		Position = UDim2.new(0, 0, 0, 6),
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 21,
		Text = "👑 VIP  x" .. Config.Monetization.VipMultiplier,
	})
	label(vipPromo, {
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 12,
		TextColor3 = Color3.fromRGB(180, 120, 30),
		Text = "✨ tap to go VIP ✨",
	})
	vipPromo.Parent = gui
	vipPromo.MouseButton1Click:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, Config.Monetization.VipGamePassId)
	end)

	local function refreshVipPromo()
		vipPromo.Visible = not player:GetAttribute("VIP")
	end
	player:GetAttributeChangedSignal("VIP"):Connect(refreshVipPromo)
	refreshVipPromo()

	-- Bob + pulse forever
	task.spawn(function()
		while vipPromo.Parent do
			TweenService:Create(vipPromo, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 274, 0, 26), Rotation = 2,
			}):Play()
			TweenService:Create(promoStroke, TweenInfo.new(1.2), { Thickness = 4 }):Play()
			task.wait(1.2)
			TweenService:Create(vipPromo, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 274, 0, 16), Rotation = -2,
			}):Play()
			TweenService:Create(promoStroke, TweenInfo.new(1.2), { Thickness = 2 }):Play()
			task.wait(1.2)
		end
	end)

	-- 🔥 Rotating "hot deal" bubble (cycles through the products)
	local deal = Instance.new("TextButton")
	deal.AnchorPoint = Vector2.new(1, 1)
	deal.Position = UDim2.new(1, -344, 1, -16)
	deal.Size = UDim2.new(0, 230, 0, 66)
	deal.BackgroundColor3 = C.Panel
	deal.BorderSizePixel = 0
	deal.Text = ""
	round(deal, 16)
	local dealStroke = Instance.new("UIStroke")
	dealStroke.Color = Color3.fromRGB(90, 200, 120)
	dealStroke.Thickness = 2.5
	dealStroke.Parent = deal
	local dealIcon = label(deal, {
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 44, 1, 0),
		TextSize = 30,
		Text = "🍪",
	})
	label(deal, {
		Position = UDim2.new(0, 58, 0, 8),
		Size = UDim2.new(1, -66, 0, 20),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(90, 170, 100),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "🔥 HOT DEAL",
	})
	local dealName = label(deal, {
		Position = UDim2.new(0, 58, 0, 30),
		Size = UDim2.new(1, -66, 0, 24),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	})
	deal.Parent = gui

	local dealIndex = 1
	local function showDeal()
		local product = Config.Monetization.Products[dealIndex]
		dealIcon.Text = product.icon
		dealName.Text = product.name
		deal.Size = UDim2.new(0, 210, 0, 60)
		TweenService:Create(deal, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 230, 0, 66),
		}):Play()
	end
	showDeal()
	task.spawn(function()
		while deal.Parent do
			task.wait(6)
			dealIndex = (dealIndex % #Config.Monetization.Products) + 1
			showDeal()
		end
	end)
	deal.MouseButton1Click:Connect(function()
		local product = Config.Monetization.Products[dealIndex]
		if product.id > 0 then
			MarketplaceService:PromptProductPurchase(player, product.id)
		end
	end)
end

return Store

--!strict
-- First-join tutorial: a friendly page-by-page guide shown only to brand
-- new players (server sets the FirstJoin attribute when no save exists).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Tutorial = {}

local player = Players.LocalPlayer
local C = Config.Colors

local PAGES = {
	{ icon = "😺", title = "Welcome to Cat Clicker!",
		body = "Click the BIG CHONKER in the middle to earn Treats. Every click counts — and upgrades make each click huge!" },
	{ icon = "🛍️", title = "The Cat Shop",
		body = "Spend Treats in the shop on the right. Cats earn Treats automatically every second, and Click Upgrades power up your taps!" },
	{ icon = "🐾", title = "Rebirth",
		body = "At 500K Treats, hit REBIRTH! Your Treats reset, but you get Cat Points (+25% ALL gains forever) and Paw Coins 🪙." },
	{ icon = "🥚", title = "Pets & Potions",
		body = "Spend Paw Coins on eggs to hatch meme cats — equip up to 10 and they roam your screen boosting everything. Brew potions in the shop for extra buffs!" },
	{ icon = "🌙", title = "Events & Dailies",
		body = "Catch special cats for boosts, ride mutation events like ACID RAIN, and claim daily rewards + your free spin. Have fun!" },
}

function Tutorial.Start()
	local function show()
		local gui = Instance.new("ScreenGui")
		gui.Name = "CatClickerTutorial"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 80
		gui.Parent = player:WaitForChild("PlayerGui")

		local overlay = Instance.new("TextButton")
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.Text = ""
		overlay.AutoButtonColor = false
		overlay.Parent = gui

		local panel = Instance.new("Frame")
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(0.5, 0.45)
		panel.Size = UDim2.new(0, 460, 0, 300)
		panel.BackgroundColor3 = C.Panel
		panel.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 24)
		corner.Parent = panel
		local stroke = Instance.new("UIStroke")
		stroke.Color = C.PinkDark
		stroke.Thickness = 3
		stroke.Parent = panel
		panel.Parent = overlay

		local icon = Instance.new("TextLabel")
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.new(0, 0, 0, 18)
		icon.Size = UDim2.new(1, 0, 0, 56)
		icon.Font = Enum.Font.FredokaOne
		icon.TextSize = 48
		icon.Text = ""
		icon.Parent = panel

		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 0, 0, 80)
		titleLabel.Size = UDim2.new(1, 0, 0, 30)
		titleLabel.Font = Enum.Font.FredokaOne
		titleLabel.TextSize = 24
		titleLabel.TextColor3 = C.PinkDark
		titleLabel.Text = ""
		titleLabel.Parent = panel

		local bodyLabel = Instance.new("TextLabel")
		bodyLabel.BackgroundTransparency = 1
		bodyLabel.Position = UDim2.new(0, 30, 0, 116)
		bodyLabel.Size = UDim2.new(1, -60, 0, 96)
		bodyLabel.Font = Enum.Font.FredokaOne
		bodyLabel.TextSize = 16
		bodyLabel.TextWrapped = true
		bodyLabel.TextColor3 = C.Text
		bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
		bodyLabel.Text = ""
		bodyLabel.Parent = panel

		local progress = Instance.new("TextLabel")
		progress.BackgroundTransparency = 1
		progress.Position = UDim2.new(0, 0, 1, -80)
		progress.Size = UDim2.new(1, 0, 0, 18)
		progress.Font = Enum.Font.FredokaOne
		progress.TextSize = 13
		progress.TextColor3 = C.TextSoft
		progress.Text = ""
		progress.Parent = panel

		local nextBtn = Instance.new("TextButton")
		nextBtn.AnchorPoint = Vector2.new(1, 1)
		nextBtn.Position = UDim2.new(1, -20, 1, -16)
		nextBtn.Size = UDim2.new(0, 150, 0, 40)
		nextBtn.BackgroundColor3 = C.PinkDark
		nextBtn.BorderSizePixel = 0
		nextBtn.Font = Enum.Font.FredokaOne
		nextBtn.TextSize = 17
		nextBtn.TextColor3 = Color3.new(1, 1, 1)
		nextBtn.Text = "NEXT ➜"
		local nextCorner = Instance.new("UICorner")
		nextCorner.CornerRadius = UDim.new(0, 12)
		nextCorner.Parent = nextBtn
		nextBtn.Parent = panel

		local skipBtn = nextBtn:Clone()
		skipBtn.AnchorPoint = Vector2.new(0, 1)
		skipBtn.Position = UDim2.new(0, 20, 1, -16)
		skipBtn.Size = UDim2.new(0, 90, 0, 40)
		skipBtn.BackgroundColor3 = C.Background
		skipBtn.TextColor3 = C.TextSoft
		skipBtn.TextSize = 14
		skipBtn.Text = "skip"
		skipBtn.Parent = panel

		local page = 0
		local function showPage()
			page += 1
			if page > #PAGES then
				gui:Destroy()
				return
			end
			local data = PAGES[page]
			icon.Text = data.icon
			titleLabel.Text = data.title
			bodyLabel.Text = data.body
			progress.Text = ("%d / %d"):format(page, #PAGES)
			nextBtn.Text = page == #PAGES and "LET'S GO! 🐾" or "NEXT ➜"
			panel.Size = UDim2.new(0, 440, 0, 285)
			TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
				Size = UDim2.new(0, 460, 0, 300),
			}):Play()
		end

		nextBtn.MouseButton1Click:Connect(showPage)
		skipBtn.MouseButton1Click:Connect(function()
			gui:Destroy()
		end)
		showPage()
	end

	-- FirstJoin is set by the server after the (async) save load
	if player:GetAttribute("FirstJoin") then
		show()
	else
		local connection
		connection = player:GetAttributeChangedSignal("FirstJoin"):Connect(function()
			if player:GetAttribute("FirstJoin") then
				connection:Disconnect()
				show()
			end
		end)
		task.delay(15, function() -- save loaded with data: never fires, clean up
			connection:Disconnect()
		end)
	end
end

return Tutorial

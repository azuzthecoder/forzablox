--!strict
-- Meme cat pets: hatch eggs with Paw Coins, equip up to 10 (duplicates
-- stack!), and equipped cats roam the whole screen with multipliers.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Pets = {}

local player = Players.LocalPlayer
local C = Config.Colors
local rng = Random.new()

local pets: { [string]: number } = {}
local equipped: { string } = {}

local gui: ScreenGui
local roamGui: ScreenGui
local panel: Frame
local equippedLine: TextLabel
local coinsLabel: TextLabel
local errorLabel: TextLabel
local openBtn: TextButton
local eggStage: Frame
local invRows: { [string]: { countLabel: TextLabel, equipLabel: TextLabel, addBtn: TextButton, removeBtn: TextButton } } = {}

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

local function petVisual(parent: Instance, petId: string, sizePx: number): Frame
	local pet = Config.PetsById[petId]
	local holder = Instance.new("Frame")
	holder.Size = UDim2.fromOffset(sizePx, sizePx)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local imageId = Config.Images.Pets[petId]
	if imageId and imageId ~= "" then
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = imageId
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = holder
	else
		local chip = Instance.new("Frame")
		chip.Size = UDim2.fromScale(1, 1)
		chip.BackgroundColor3 = C.Panel
		chip.BorderSizePixel = 0
		round(chip, 0)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Config.RarityColors[pet and pet.rarity or "Common"]
		stroke.Thickness = 3
		stroke.Parent = chip
		chip.Parent = holder
		label(chip, {
			Size = UDim2.fromScale(1, 1),
			TextSize = math.floor(sizePx * 0.55),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = pet and pet.emoji or "🐱",
		})
	end
	return holder
end

-- ============================ ROAMING PETS ============================

local function refreshRoamers()
	roamGui:ClearAllChildren()
	for _, petId in equipped do
		local holder = petVisual(roamGui, petId, 130)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(rng:NextNumber(0.08, 0.6), rng:NextNumber(0.2, 0.85))

		task.spawn(function()
			while holder.Parent do
				-- Occasionally get the zoomies (fast dash), otherwise stroll
				local zoomies = rng:NextNumber() < 0.25
				local target = UDim2.fromScale(rng:NextNumber(0.05, 0.62), rng:NextNumber(0.15, 0.88))
				local travelTime = zoomies and rng:NextNumber(0.7, 1.2) or rng:NextNumber(2.5, 4.5)
				TweenService:Create(holder,
					TweenInfo.new(travelTime, Enum.EasingStyle.Sine), { Position = target }):Play()
				local waddleEnd = os.clock() + travelTime
				while os.clock() < waddleEnd and holder.Parent do
					TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Sine),
						{ Rotation = zoomies and 14 or 6 }):Play()
					task.wait(0.25)
					TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Sine),
						{ Rotation = zoomies and -14 or -6 }):Play()
					task.wait(0.25)
				end
				TweenService:Create(holder, TweenInfo.new(0.2), { Rotation = 0 }):Play()
				task.wait(rng:NextNumber(0.5, 2.5))
			end
		end)
	end
end

-- ============================ REFRESH ============================

local function equippedCopiesOf(petId: string): number
	local n = 0
	for _, id in equipped do
		if id == petId then
			n += 1
		end
	end
	return n
end

local function refreshInventory()
	local totalMult = 1
	for _, petId in equipped do
		local pet = Config.PetsById[petId]
		if pet then
			totalMult *= pet.mult
		end
	end
	equippedLine.Text = ("Equipped: %d/%d  •  x%.2f ALL treats"):format(
		#equipped, Config.Pets.MaxEquipped, totalMult)

	for petId, entry in invRows do
		local owned = pets[petId] or 0
		local copies = equippedCopiesOf(petId)
		entry.countLabel.Text = "owned x" .. owned
		entry.equipLabel.Text = copies > 0 and ("⭐ %d equipped"):format(copies) or ""
		entry.addBtn.BackgroundColor3 = (owned > copies and #equipped < Config.Pets.MaxEquipped)
			and Color3.fromRGB(90, 200, 120) or C.PanelShadow
		entry.removeBtn.BackgroundColor3 = copies > 0 and Color3.fromRGB(226, 96, 96) or C.PanelShadow
	end

	local coins = (player:GetAttribute("PawCoins") :: number?) or 0
	coinsLabel.Text = "🪙 " .. tostring(math.floor(coins))
	openBtn.BackgroundColor3 = coins >= Config.Pets.EggCost and C.PinkDark or C.PanelShadow
end

-- ============================ EGG HATCH ============================

local hatching = false

local function showHatch(petId: string)
	local pet = Config.PetsById[petId]
	if not pet or hatching then
		return
	end
	hatching = true
	eggStage:ClearAllChildren()

	local rarityColor = Config.RarityColors[pet.rarity]

	local egg = label(eggStage, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(120, 120),
		TextSize = 92,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🥚",
	})

	task.spawn(function()
		-- Rattle harder and harder
		for i = 1, 7 do
			local angle = 8 + i * 2
			TweenService:Create(egg, TweenInfo.new(0.08), { Rotation = angle }):Play()
			task.wait(0.08)
			TweenService:Create(egg, TweenInfo.new(0.08), { Rotation = -angle }):Play()
			task.wait(0.08)
		end
		egg.Text = "💥"
		task.wait(0.12)
		egg:Destroy()

		-- Rarity flash + sparkle burst
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = rarityColor
		flash.BackgroundTransparency = 0.35
		flash.BorderSizePixel = 0
		round(flash, 14)
		flash.Parent = eggStage
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		task.delay(0.65, function()
			flash:Destroy()
		end)
		for i = 1, 10 do
			local sparkle = label(eggStage, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.42),
				Size = UDim2.fromOffset(28, 28),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = "✨",
			})
			local angle = (i / 10) * math.pi * 2
			TweenService:Create(sparkle, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, math.cos(angle) * 95, 0.42, math.sin(angle) * 95),
				TextTransparency = 1,
				Rotation = 180,
			}):Play()
			task.delay(0.75, function()
				sparkle:Destroy()
			end)
		end

		-- Pet pops in with overshoot
		local visual = petVisual(eggStage, petId, 130)
		visual.AnchorPoint = Vector2.new(0.5, 0.5)
		visual.Position = UDim2.fromScale(0.5, 0.42)
		visual.Size = UDim2.fromOffset(10, 10)
		TweenService:Create(visual, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(130, 130),
		}):Play()

		local nameLabel = label(eggStage, {
			Position = UDim2.new(0, 0, 0.68, 0),
			Size = UDim2.new(1, 0, 0, 28),
			TextSize = 21,
			TextColor3 = rarityColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = pet.name,
		})
		local nameStroke = Instance.new("UIStroke")
		nameStroke.Color = Color3.new(1, 1, 1)
		nameStroke.Thickness = 2
		nameStroke.Parent = nameLabel
		label(eggStage, {
			Position = UDim2.new(0, 0, 0.68, 30),
			Size = UDim2.new(1, 0, 0, 20),
			TextSize = 14,
			TextColor3 = C.TextSoft,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = ("%s  •  x%.2f all treats"):format(pet.rarity, pet.mult),
		})
		hatching = false
	end)
end

local function showIdleEgg()
	eggStage:ClearAllChildren()
	local egg = label(eggStage, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(120, 120),
		TextSize = 92,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🥚",
	})
	-- Gentle idle wobble
	task.spawn(function()
		while egg.Parent do
			TweenService:Create(egg, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Rotation = 5 }):Play()
			task.wait(0.9)
			TweenService:Create(egg, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Rotation = -5 }):Play()
			task.wait(0.9)
		end
	end)
end

-- ============================ BUILD ============================

function Pets.Start()
	local petSyncRemote = ReplicatedStorage:WaitForChild("PetSync") :: RemoteEvent
	local openEgg = ReplicatedStorage:WaitForChild("OpenEgg") :: RemoteFunction
	local equipPet = ReplicatedStorage:WaitForChild("EquipPet") :: RemoteFunction

	roamGui = Instance.new("ScreenGui")
	roamGui.Name = "CatClickerRoamers"
	roamGui.ResetOnSpawn = false
	roamGui.DisplayOrder = 5
	roamGui.Parent = player:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "CatClickerPets"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 25
	gui.Parent = player.PlayerGui

	-- Big bubble toggle button
	local toggle = button(gui, "", {
		Position = UDim2.new(0, 12, 0, 350),
		Size = UDim2.new(0, 158, 0, 58),
		BackgroundColor3 = C.Panel,
	})
	round(toggle, 20)
	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = C.PinkDark
	toggleStroke.Thickness = 3
	toggleStroke.Parent = toggle
	local toggleText = label(toggle, {
		Size = UDim2.fromScale(1, 1),
		TextSize = 22,
		TextColor3 = C.PinkDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🥚 PETS",
	})
	local toggleTextStroke = Instance.new("UIStroke")
	toggleTextStroke.Color = Color3.new(1, 1, 1)
	toggleTextStroke.Thickness = 1.5
	toggleTextStroke.Parent = toggleText
	task.spawn(function()
		while toggle.Parent do
			TweenService:Create(toggle, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 12, 0, 356),
			}):Play()
			task.wait(1.4)
			TweenService:Create(toggle, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 12, 0, 350),
			}):Play()
			task.wait(1.4)
		end
	end)

	-- Main panel
	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 680, 0, 520)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	round(panel, 22)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Pink
	stroke.Thickness = 3
	stroke.Parent = panel
	panel.Parent = gui

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			refreshInventory()
		end
	end)

	local title = label(panel, {
		Position = UDim2.new(0, 24, 0, 14),
		Size = UDim2.new(0, 260, 0, 30),
		TextSize = 24,
		TextColor3 = C.PinkDark,
		Text = "🥚 Meme Cat Pets",
	})
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(1, 1, 1)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = title

	equippedLine = label(panel, {
		Position = UDim2.new(0, 24, 0, 46),
		Size = UDim2.new(0, 400, 0, 20),
		TextSize = 14,
		TextColor3 = C.TextSoft,
		Text = "",
	})

	coinsLabel = label(panel, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -60, 0, 16),
		Size = UDim2.new(0, 140, 0, 26),
		TextSize = 18,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "🪙 0",
	})
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

	-- ============== Egg pane (left) ==============
	local eggPane = Instance.new("Frame")
	eggPane.Position = UDim2.new(0, 20, 0, 74)
	eggPane.Size = UDim2.new(0, 250, 1, -94)
	eggPane.BackgroundColor3 = C.Background
	eggPane.BorderSizePixel = 0
	round(eggPane, 16)
	eggPane.Parent = panel

	eggStage = Instance.new("Frame")
	eggStage.Size = UDim2.new(1, 0, 1, -110)
	eggStage.BackgroundTransparency = 1
	eggStage.ClipsDescendants = true
	eggStage.Parent = eggPane
	showIdleEgg()

	errorLabel = label(eggPane, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -66),
		Size = UDim2.new(1, -24, 0, 40),
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(220, 90, 90),
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "",
	})

	openBtn = button(eggPane, ("OPEN EGG  (%d 🪙)"):format(Config.Pets.EggCost), {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -28, 0, 44),
		BackgroundColor3 = C.PinkDark,
		TextSize = 17,
	})
	openBtn.MouseButton1Click:Connect(function()
		if hatching then
			return
		end
		errorLabel.Text = ""
		local ok, result = openEgg:InvokeServer()
		if ok then
			showHatch(result)
		else
			errorLabel.Text = tostring(result)
		end
	end)

	-- ============== Inventory (right) ==============
	label(panel, {
		Position = UDim2.new(0, 290, 0, 74),
		Size = UDim2.new(0, 300, 0, 20),
		TextSize = 14,
		TextColor3 = C.TextSoft,
		Text = "Your cats — stack duplicates for more power!",
	})

	for i, pet in Config.Pets.List do
		local row = Instance.new("Frame")
		row.Position = UDim2.new(0, 290, 0, 100 + (i - 1) * 100)
		row.Size = UDim2.new(1, -310, 0, 92)
		row.BackgroundColor3 = C.Background
		row.BorderSizePixel = 0
		round(row, 14)
		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Config.RarityColors[pet.rarity]
		rowStroke.Thickness = 2
		rowStroke.Transparency = 0.4
		rowStroke.Parent = row
		row.Parent = panel

		local visual = petVisual(row, pet.id, 72)
		visual.Position = UDim2.new(0, 10, 0.5, -36)

		label(row, {
			Position = UDim2.new(0, 92, 0, 8),
			Size = UDim2.new(1, -200, 0, 22),
			TextSize = 16,
			TextColor3 = Config.RarityColors[pet.rarity],
			Text = pet.name,
		})
		label(row, {
			Position = UDim2.new(0, 92, 0, 32),
			Size = UDim2.new(1, -200, 0, 16),
			TextSize = 12,
			TextColor3 = C.TextSoft,
			Text = ("%s • x%.2f each"):format(pet.rarity, pet.mult),
		})
		local countLabel = label(row, {
			Position = UDim2.new(0, 92, 0, 50),
			Size = UDim2.new(0, 100, 0, 16),
			TextSize = 13,
			Text = "owned x0",
		})
		local equipLabel = label(row, {
			Position = UDim2.new(0, 92, 0, 68),
			Size = UDim2.new(0, 150, 0, 16),
			TextSize = 13,
			TextColor3 = C.Accent,
			Text = "",
		})

		local addBtn = button(row, "＋ EQUIP", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 10),
			Size = UDim2.new(0, 92, 0, 34),
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(90, 200, 120),
		})
		local removeBtn = button(row, "－ REMOVE", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -10, 1, -10),
			Size = UDim2.new(0, 92, 0, 34),
			TextSize = 13,
			BackgroundColor3 = Color3.fromRGB(226, 96, 96),
		})
		addBtn.MouseButton1Click:Connect(function()
			local ok, message = equipPet:InvokeServer(pet.id, "add")
			if not ok and message then
				errorLabel.Text = tostring(message)
			end
		end)
		removeBtn.MouseButton1Click:Connect(function()
			equipPet:InvokeServer(pet.id, "remove")
		end)

		invRows[pet.id] = {
			countLabel = countLabel, equipLabel = equipLabel,
			addBtn = addBtn, removeBtn = removeBtn,
		}
	end

	-- ============================ SYNC ============================

	petSyncRemote.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" then
			pets = payload.pets or {}
			equipped = payload.equipped or {}
			refreshRoamers()
			if panel.Visible then
				refreshInventory()
			end
		end
	end)
	petSyncRemote:FireServer()

	player:GetAttributeChangedSignal("PawCoins"):Connect(function()
		if panel.Visible then
			refreshInventory()
		end
	end)
end

return Pets

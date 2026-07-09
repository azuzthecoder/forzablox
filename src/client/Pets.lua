--!strict
-- Meme cat pets: open eggs with Paw Coins, equip up to 3, and equipped
-- cats roam around the bottom of the screen giving stacking multipliers.
-- Pet pictures come from Config.Images.Pets (emoji fallback until set).

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
local roamers: { [string]: Frame } = {}
local invRows: { [string]: { row: Frame, countLabel: TextLabel, equipBtn: TextButton } } = {}

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

-- Builds a pet face: real image if configured, emoji chip otherwise
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
	for petId, roamer in roamers do
		if not table.find(equipped, petId) then
			roamer:Destroy()
			roamers[petId] = nil
		end
	end
	for _, petId in equipped do
		if not roamers[petId] then
			local holder = petVisual(roamGui, petId, 92)
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromScale(rng:NextNumber(0.1, 0.6), rng:NextNumber(0.74, 0.9))
			roamers[petId] = holder

			-- Wander loop: stroll to a new spot, bob, repeat
			task.spawn(function()
				while holder.Parent do
					local target = UDim2.fromScale(rng:NextNumber(0.08, 0.62), rng:NextNumber(0.72, 0.9))
					local walk = TweenService:Create(holder,
						TweenInfo.new(rng:NextNumber(2.5, 4.5), Enum.EasingStyle.Sine), { Position = target })
					walk:Play()
					-- Waddle while walking
					local waddleEnd = os.clock() + 2.5
					while os.clock() < waddleEnd and holder.Parent do
						TweenService:Create(holder, TweenInfo.new(0.3, Enum.EasingStyle.Sine),
							{ Rotation = 6 }):Play()
						task.wait(0.3)
						TweenService:Create(holder, TweenInfo.new(0.3, Enum.EasingStyle.Sine),
							{ Rotation = -6 }):Play()
						task.wait(0.3)
					end
					TweenService:Create(holder, TweenInfo.new(0.2), { Rotation = 0 }):Play()
					task.wait(rng:NextNumber(1, 3))
				end
			end)
		end
	end
end

-- ============================ INVENTORY UI ============================

local eggResult: Frame
local resultVisual: Frame? = nil
local resultName: TextLabel
local resultInfo: TextLabel
local coinsLabel: TextLabel
local openBtn: TextButton

local function refreshInventory()
	for petId, entry in invRows do
		local count = pets[petId] or 0
		local isEquipped = table.find(equipped, petId) ~= nil
		entry.row.Visible = count > 0
		entry.countLabel.Text = "x" .. count
		entry.equipBtn.Text = isEquipped and "UNEQUIP" or "EQUIP"
		entry.equipBtn.BackgroundColor3 = isEquipped and C.PanelShadow or C.Pink
	end
	local coins = (player:GetAttribute("PawCoins") :: number?) or 0
	coinsLabel.Text = "🪙 " .. tostring(math.floor(coins)) .. " Paw Coins"
	openBtn.BackgroundColor3 = coins >= Config.Pets.EggCost and C.PinkDark or C.PanelShadow
end

local function showHatch(petId: string)
	local pet = Config.PetsById[petId]
	if not pet then
		return
	end
	if resultVisual then
		resultVisual:Destroy()
	end
	eggResult.Visible = true
	resultName.Text = "🥚 cracking..."
	resultName.TextColor3 = C.Text
	resultInfo.Text = ""

	-- Shake an egg, then reveal
	local egg = label(eggResult, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(90, 90),
		TextSize = 64,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🥚",
	})
	task.spawn(function()
		for _ = 1, 5 do
			TweenService:Create(egg, TweenInfo.new(0.1), { Rotation = 14 }):Play()
			task.wait(0.1)
			TweenService:Create(egg, TweenInfo.new(0.1), { Rotation = -14 }):Play()
			task.wait(0.1)
		end
		egg:Destroy()
		local visual = petVisual(eggResult, petId, 110)
		visual.AnchorPoint = Vector2.new(0.5, 0.5)
		visual.Position = UDim2.fromScale(0.5, 0.42)
		visual.Size = UDim2.fromOffset(10, 10)
		resultVisual = visual
		TweenService:Create(visual, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(110, 110),
		}):Play()
		resultName.Text = pet.name
		resultName.TextColor3 = Config.RarityColors[pet.rarity]
		resultInfo.Text = ("%s  •  x%.2f all treats"):format(pet.rarity, pet.mult)
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

	-- Toggle button (left column)
	local toggle = button(gui, "🥚", {
		Position = UDim2.new(0, 12, 0, 354),
		Size = UDim2.new(0, 46, 0, 46),
		TextSize = 22,
	})
	round(toggle, 0)

	-- Main panel
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 520, 0, 420)
	panel.BackgroundColor3 = C.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	round(panel, 18)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Pink
	stroke.Thickness = 2
	stroke.Parent = panel
	panel.Parent = gui

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			refreshInventory()
		end
	end)

	label(panel, {
		Position = UDim2.new(0, 20, 0, 12),
		Size = UDim2.new(0, 300, 0, 28),
		TextSize = 22,
		TextColor3 = C.PinkDark,
		Text = "🥚 Meme Cat Pets",
	})
	coinsLabel = label(panel, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -56, 0, 14),
		Size = UDim2.new(0, 220, 0, 24),
		TextSize = 16,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "🪙 0 Paw Coins",
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

	-- Egg section (left half)
	local eggPane = Instance.new("Frame")
	eggPane.Position = UDim2.new(0, 16, 0, 52)
	eggPane.Size = UDim2.new(0, 220, 1, -68)
	eggPane.BackgroundColor3 = C.Background
	eggPane.BorderSizePixel = 0
	round(eggPane, 14)
	eggPane.Parent = panel

	eggResult = Instance.new("Frame")
	eggResult.Size = UDim2.new(1, 0, 1, -60)
	eggResult.BackgroundTransparency = 1
	eggResult.Visible = false
	eggResult.Parent = eggPane

	resultName = label(eggResult, {
		Position = UDim2.new(0, 0, 0.62, 0),
		Size = UDim2.new(1, 0, 0, 26),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "",
	})
	resultInfo = label(eggResult, {
		Position = UDim2.new(0, 0, 0.62, 28),
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 14,
		TextColor3 = C.TextSoft,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "",
	})

	local idleEgg = label(eggPane, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.35),
		Size = UDim2.fromOffset(100, 100),
		TextSize = 72,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "🥚",
	})

	openBtn = button(eggPane, ("OPEN EGG  (%d 🪙)"):format(Config.Pets.EggCost), {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -24, 0, 42),
		BackgroundColor3 = C.PinkDark,
	})
	openBtn.MouseButton1Click:Connect(function()
		local ok, result = openEgg:InvokeServer()
		if ok then
			idleEgg.Visible = false
			showHatch(result)
		else
			resultName.Text = ""
			resultInfo.Text = ""
			eggResult.Visible = true
			resultName.Text = tostring(result)
			resultName.TextColor3 = Color3.fromRGB(220, 90, 90)
			resultName.TextSize = 14
			task.delay(2.5, function()
				resultName.TextSize = 20
			end)
		end
	end)

	-- Inventory (right half)
	label(panel, {
		Position = UDim2.new(0, 252, 0, 52),
		Size = UDim2.new(0, 240, 0, 20),
		TextSize = 15,
		TextColor3 = C.TextSoft,
		Text = ("Your cats (equip up to %d):"):format(Config.Pets.MaxEquipped),
	})

	for i, pet in Config.Pets.List do
		local row = Instance.new("Frame")
		row.Position = UDim2.new(0, 252, 0, 76 + (i - 1) * 82)
		row.Size = UDim2.new(1, -268, 0, 74)
		row.BackgroundColor3 = C.Background
		row.BorderSizePixel = 0
		row.Visible = false
		round(row, 12)
		row.Parent = panel

		local visual = petVisual(row, pet.id, 58)
		visual.Position = UDim2.new(0, 8, 0.5, -29)

		label(row, {
			Position = UDim2.new(0, 76, 0, 8),
			Size = UDim2.new(1, -160, 0, 20),
			TextSize = 15,
			TextColor3 = Config.RarityColors[pet.rarity],
			Text = pet.name,
		})
		label(row, {
			Position = UDim2.new(0, 76, 0, 30),
			Size = UDim2.new(1, -160, 0, 16),
			TextSize = 12,
			TextColor3 = C.TextSoft,
			Text = ("%s • x%.2f all treats"):format(pet.rarity, pet.mult),
		})
		local countLabel = label(row, {
			Position = UDim2.new(0, 76, 0, 48),
			Size = UDim2.new(0, 60, 0, 16),
			TextSize = 13,
			Text = "x0",
		})
		local equipBtn = button(row, "EQUIP", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 82, 0, 34),
			TextSize = 13,
		})
		equipBtn.MouseButton1Click:Connect(function()
			equipPet:InvokeServer(pet.id)
		end)

		invRows[pet.id] = { row = row, countLabel = countLabel, equipBtn = equipBtn }
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

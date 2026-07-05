--!strict
-- Garage (toggle with G): spawn owned cars and repaint the active one.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CarCatalog = require(Shared:WaitForChild("CarCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(script.Parent.Theme)
local ClientState = require(script.Parent.Parent.ClientState)

local GarageUI = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: ScrollingFrame

local PAINTS = {
	Color3.fromRGB(240, 240, 244), Color3.fromRGB(24, 24, 28), Color3.fromRGB(190, 22, 34),
	Color3.fromRGB(255, 176, 32), Color3.fromRGB(255, 214, 10), Color3.fromRGB(80, 220, 130),
	Color3.fromRGB(12, 108, 92), Color3.fromRGB(0, 229, 255), Color3.fromRGB(38, 112, 255),
	Color3.fromRGB(88, 12, 140), Color3.fromRGB(255, 62, 150), Color3.fromRGB(150, 160, 176),
}

local function rebuild()
	for _, child in list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local spawnCar = Remotes.Get("SpawnCar") :: RemoteEvent
	local order = 0
	for _, def in CarCatalog.Cars do
		if ClientState.Owns(def.id) then
			order += 1
			local row = Theme.Button(list, "  " .. def.name .. "  •  " .. def.class, {
				Size = UDim2.new(1, -8, 0, 40),
				BackgroundColor3 = ClientState.Profile.activeCar == def.id
					and Theme.Colors.PanelLight or Theme.Colors.Panel,
				Font = Theme.FontBold, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = order,
			})
			local tag = Theme.Label(row, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 60, 0, 20),
				Font = Theme.FontHeavy, TextSize = 13,
				TextColor3 = Theme.Colors.Accent2,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "SPAWN",
			})
			tag.Parent = row
			row.MouseButton1Click:Connect(function()
				spawnCar:FireServer(def.id)
				gui.Enabled = false
			end)
		end
	end
end

function GarageUI.Start()
	gui = Instance.new("ScreenGui")
	gui.Name = "ForzaBloxGarage"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Theme.Panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 420, 0, 480),
	})
	Theme.Stroke(panel, Theme.Colors.Accent2, 2, 0.3)

	Theme.Label(panel, {
		Position = UDim2.new(0, 18, 0, 12),
		Size = UDim2.new(0, 300, 0, 28),
		Font = Theme.FontHeavy, TextSize = 22,
		Text = "MY GARAGE",
	})
	local close = Theme.Button(panel, "X", {
		Position = UDim2.new(1, -48, 0, 12),
		Size = UDim2.new(0, 32, 0, 28),
		BackgroundColor3 = Theme.Colors.PanelLight,
	})
	close.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 18, 0, 50)
	list.Size = UDim2.new(1, -36, 1, -170)
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

	-- Paint palette (applies to the currently spawned car)
	Theme.Label(panel, {
		Position = UDim2.new(0, 18, 1, -110),
		Size = UDim2.new(1, -36, 0, 18),
		Font = Theme.FontBold, TextSize = 13,
		TextColor3 = Theme.Colors.SubText,
		Text = "PAINT (applies to spawned car)",
	})
	local setColor = Remotes.Get("SetCarColor") :: RemoteEvent
	for i, color in PAINTS do
		local swatch = Theme.Button(panel, "", {
			Position = UDim2.new(0, 18 + ((i - 1) % 6) * 64, 1, -86 + math.floor((i - 1) / 6) * 38),
			Size = UDim2.new(0, 56, 0, 30),
			BackgroundColor3 = color,
		})
		swatch.MouseButton1Click:Connect(function()
			setColor:FireServer(
				math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
		end)
	end

	ClientState.ProfileChanged.Event:Connect(function()
		if gui.Enabled then
			rebuild()
		end
	end)

	local function toggle()
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			rebuild()
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.G then
			toggle()
		end
	end)

	local open = Remotes.Get("OpenGarage") :: RemoteEvent
	open.OnClientEvent:Connect(function()
		gui.Enabled = true
		rebuild()
	end)
end

return GarageUI

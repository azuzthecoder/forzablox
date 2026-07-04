--!strict
-- Toast notifications (top right), driven by the server Notify remote and
-- available locally via Notifications.Push.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(script.Parent.Theme)

local Notifications = {}

local player = Players.LocalPlayer
local container: Frame

local KIND_COLORS: { [string]: Color3 } = {
	info = Theme.Colors.Accent2,
	success = Theme.Colors.Good,
	error = Theme.Colors.Bad,
}

function Notifications.Push(text: string, kind: string?)
	local accent = KIND_COLORS[kind or "info"] or Theme.Colors.Accent2

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 44)
	toast.BackgroundColor3 = Theme.Colors.Panel
	toast.BackgroundTransparency = 0.12
	toast.BorderSizePixel = 0
	Theme.Corner(toast, 10)
	Theme.Stroke(toast, accent, 1.5, 0.25)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, -12)
	bar.Position = UDim2.new(0, 6, 0, 6)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	Theme.Corner(bar, 2)
	bar.Parent = toast

	Theme.Label(toast, {
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.new(0, 18, 0, 0),
		Font = Theme.FontBold,
		TextSize = 14,
		TextWrapped = true,
		Text = text,
	})

	toast.Parent = container

	toast.BackgroundTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.12,
	}):Play()

	task.delay(4.5, function()
		local out = TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		})
		out.Completed:Connect(function()
			toast:Destroy()
		end)
		out:Play()
	end)
end

function Notifications.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ForzaBloxNotifications"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")

	container = Instance.new("Frame")
	container.Size = UDim2.new(0, 300, 1, -40)
	container.Position = UDim2.new(1, -320, 0, 70)
	container.BackgroundTransparency = 1
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = container

	local notify = Remotes.Get("Notify") :: RemoteEvent
	notify.OnClientEvent:Connect(function(text, kind)
		if type(text) == "string" then
			Notifications.Push(text, type(kind) == "string" and kind or "info")
		end
	end)
end

return Notifications

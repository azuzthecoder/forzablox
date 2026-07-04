--!strict
-- Shared look & feel for all ForzaBlox UI: dark glass panels with the
-- festival's pink/cyan accent palette, plus small builder helpers.

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(14, 15, 22),
	Panel = Color3.fromRGB(22, 24, 34),
	PanelLight = Color3.fromRGB(34, 37, 52),
	Accent = Color3.fromRGB(255, 62, 150), -- festival pink
	Accent2 = Color3.fromRGB(0, 229, 255), -- horizon cyan
	Text = Color3.fromRGB(240, 242, 248),
	SubText = Color3.fromRGB(150, 155, 175),
	Good = Color3.fromRGB(80, 220, 130),
	Bad = Color3.fromRGB(255, 92, 92),
	Gold = Color3.fromRGB(255, 202, 40),
}

Theme.FontHeavy = Enum.Font.GothamBlack
Theme.FontBold = Enum.Font.GothamBold
Theme.Font = Enum.Font.Gotham

function Theme.Corner(instance: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

function Theme.Stroke(instance: Instance, color: Color3, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

function Theme.Gradient(instance: Instance, colorA: Color3, colorB: Color3, rotation: number?)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = rotation or 0
	gradient.Parent = instance
end

function Theme.Panel(parent: Instance, props: { [string]: any }?): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	if props then
		for key, value in props do
			(frame :: any)[key] = value
		end
	end
	Theme.Corner(frame, 12)
	frame.Parent = parent
	return frame
end

function Theme.Label(parent: Instance, props: { [string]: any }?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Theme.FontBold
	label.TextColor3 = Theme.Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	if props then
		for key, value in props do
			(label :: any)[key] = value
		end
	end
	label.Parent = parent
	return label
end

function Theme.Button(parent: Instance, text: string, props: { [string]: any }?): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = Theme.Colors.Accent
	button.BorderSizePixel = 0
	button.Font = Theme.FontHeavy
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	Theme.Corner(button, 8)
	button.Parent = parent
	return button
end

function Theme.FormatCredits(amount: number): string
	local formatted = tostring(math.floor(amount))
	while true do
		local replaced
		formatted, replaced = formatted:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return formatted .. " CR"
end

return Theme

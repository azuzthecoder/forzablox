--!strict
-- Forza Horizon-style "golden hour" visual pass: warm low sun, volumetric-ish
-- atmosphere, bloom, sun rays and filmic color grading. For best results the
-- place should use Lighting.Technology = Future (set via default.project.json,
-- or manually in Studio — it cannot be changed by scripts at runtime).

local Lighting = game:GetService("Lighting")

local LightingSetup = {}

local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

function LightingSetup.Apply()
	-- Golden hour sun
	Lighting.ClockTime = 16.6
	Lighting.GeographicLatitude = 32
	Lighting.Brightness = 3.2
	Lighting.ExposureCompensation = 0.15
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.15
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.Ambient = Color3.fromRGB(70, 68, 82)
	Lighting.OutdoorAmbient = Color3.fromRGB(118, 110, 104)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 226, 188)
	Lighting.ColorShift_Bottom = Color3.fromRGB(140, 120, 150)

	local atmosphere = ensure("Atmosphere", "Atmosphere") :: Atmosphere
	atmosphere.Density = 0.34
	atmosphere.Offset = 0.6
	atmosphere.Color = Color3.fromRGB(204, 180, 168)
	atmosphere.Decay = Color3.fromRGB(120, 90, 106)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.9

	local bloom = ensure("BloomEffect", "ForzaBloom") :: BloomEffect
	bloom.Intensity = 0.65
	bloom.Size = 32
	bloom.Threshold = 1.05

	local rays = ensure("SunRaysEffect", "ForzaSunRays") :: SunRaysEffect
	rays.Intensity = 0.12
	rays.Spread = 0.8

	local grade = ensure("ColorCorrectionEffect", "ForzaGrade") :: ColorCorrectionEffect
	grade.Brightness = 0.02
	grade.Contrast = 0.12
	grade.Saturation = 0.14
	grade.TintColor = Color3.fromRGB(255, 248, 240)

	local dof = ensure("DepthOfFieldEffect", "ForzaDOF") :: DepthOfFieldEffect
	dof.FarIntensity = 0.1
	dof.FocusDistance = 60
	dof.InFocusRadius = 140
	dof.NearIntensity = 0.15

	-- Soft scattered clouds
	local terrain = workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	if not clouds then
		clouds = Instance.new("Clouds")
		clouds.Parent = terrain
	end
	clouds.Cover = 0.52
	clouds.Density = 0.62
	clouds.Color = Color3.fromRGB(255, 240, 228)
end

return LightingSetup

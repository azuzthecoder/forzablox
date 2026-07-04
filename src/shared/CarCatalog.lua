--!strict
-- Every car in ForzaBlox. Stats are used directly by the driving model:
--   topSpeedMph : top speed shown/enforced
--   power       : acceleration (studs/s^2 of drive force per unit mass)
--   grip        : tire lateral grip (higher = more planted, lower = slidey)
--   brake       : braking deceleration (studs/s^2)
--   drive       : "RWD" | "AWD"
--   bodyStyle   : silhouette used by CarBuilder
--   class       : D, C, B, A, S1, S2, X (Forza-style performance classes)

export type CarDef = {
	id: string,
	name: string,
	brand: string,
	class: string,
	price: number,
	topSpeedMph: number,
	power: number,
	grip: number,
	brake: number,
	drive: string,
	bodyStyle: string,
	spoiler: boolean,
	defaultColor: Color3,
	description: string,
}

local CarCatalog = {}

CarCatalog.Classes = { "D", "C", "B", "A", "S1", "S2", "X" }

CarCatalog.ClassColors = {
	D = Color3.fromRGB(96, 178, 244),
	C = Color3.fromRGB(255, 202, 40),
	B = Color3.fromRGB(255, 138, 43),
	A = Color3.fromRGB(239, 68, 88),
	S1 = Color3.fromRGB(186, 85, 255),
	S2 = Color3.fromRGB(64, 156, 255),
	X = Color3.fromRGB(120, 255, 154),
}

CarCatalog.Cars = {
	-- ============================== D CLASS ==============================
	{
		id = "pico_dash", name = "Pico Dash", brand = "Pico", class = "D",
		price = 12000, topSpeedMph = 98, power = 36, grip = 1.00, brake = 62,
		drive = "RWD", bodyStyle = "hatch", spoiler = false,
		defaultColor = Color3.fromRGB(240, 240, 244),
		description = "A cheerful little city hatch. Everyone starts somewhere.",
	},
	{
		id = "vulpes_gt68", name = "Vulpes GT 1968", brand = "Vulpes", class = "D",
		price = 18000, topSpeedMph = 122, power = 42, grip = 0.92, brake = 60,
		drive = "RWD", bodyStyle = "muscle", spoiler = false,
		defaultColor = Color3.fromRGB(158, 34, 34),
		description = "Sixties muscle with more bark than bite. Loves a burnout.",
	},
	-- ============================== C CLASS ==============================
	{
		id = "comet_rs", name = "Comet RS", brand = "Comet", class = "C",
		price = 32000, topSpeedMph = 138, power = 48, grip = 1.14, brake = 72,
		drive = "AWD", bodyStyle = "hatch", spoiler = true,
		defaultColor = Color3.fromRGB(38, 112, 255),
		description = "Rally-bred hot hatch. All-wheel drive, all the fun.",
	},
	{
		id = "bandito_v8", name = "Bandito V8", brand = "Bandito", class = "C",
		price = 41000, topSpeedMph = 148, power = 52, grip = 1.02, brake = 70,
		drive = "RWD", bodyStyle = "muscle", spoiler = false,
		defaultColor = Color3.fromRGB(24, 24, 28),
		description = "Modern muscle. Straight lines are its love language.",
	},
	-- ============================== B CLASS ==============================
	{
		id = "kestrel_gt", name = "Kestrel GT", brand = "Kestrel", class = "B",
		price = 68000, topSpeedMph = 165, power = 58, grip = 1.20, brake = 82,
		drive = "RWD", bodyStyle = "coupe", spoiler = true,
		defaultColor = Color3.fromRGB(255, 176, 32),
		description = "A balanced sports coupe and the perfect first upgrade.",
	},
	{
		id = "aurora_s", name = "Aurora S", brand = "Aurora", class = "B",
		price = 74000, topSpeedMph = 160, power = 56, grip = 1.24, brake = 84,
		drive = "AWD", bodyStyle = "sedan", spoiler = false,
		defaultColor = Color3.fromRGB(210, 214, 222),
		description = "Executive super-sedan. Quietly ruthless in the corners.",
	},
	{
		id = "dune_runner", name = "Dune Runner 4x4", brand = "Trailhawk", class = "B",
		price = 59000, topSpeedMph = 128, power = 50, grip = 1.10, brake = 76,
		drive = "AWD", bodyStyle = "suv", spoiler = false,
		defaultColor = Color3.fromRGB(94, 122, 76),
		description = "Built for the wild side of the map. Hills are a suggestion.",
	},
	-- ============================== A CLASS ==============================
	{
		id = "raijin_zxr", name = "Raijin ZX-R", brand = "Raijin", class = "A",
		price = 132000, topSpeedMph = 186, power = 66, grip = 1.30, brake = 92,
		drive = "RWD", bodyStyle = "coupe", spoiler = true,
		defaultColor = Color3.fromRGB(235, 238, 245),
		description = "A JDM legend. Precise, lively, and endlessly tunable.",
	},
	{
		id = "monarch_gtb", name = "Monarch GTB", brand = "Monarch", class = "A",
		price = 158000, topSpeedMph = 192, power = 68, grip = 1.28, brake = 94,
		drive = "RWD", bodyStyle = "super", spoiler = false,
		defaultColor = Color3.fromRGB(190, 22, 34),
		description = "Front-engined grand tourer with a serious V12 attitude.",
	},
	{
		id = "strada_tt", name = "Strada TT", brand = "Strada", class = "A",
		price = 121000, topSpeedMph = 181, power = 64, grip = 1.34, brake = 96,
		drive = "AWD", bodyStyle = "coupe", spoiler = false,
		defaultColor = Color3.fromRGB(70, 74, 82),
		description = "Grip-first engineering. Corners like it's on rails.",
	},
	-- ============================== S1 CLASS ==============================
	{
		id = "tempesta_v10", name = "Tempesta V10", brand = "Tempesta", class = "S1",
		price = 425000, topSpeedMph = 205, power = 78, grip = 1.38, brake = 104,
		drive = "RWD", bodyStyle = "super", spoiler = true,
		defaultColor = Color3.fromRGB(255, 214, 10),
		description = "An Italian thunderstorm. Loud, angry, unforgettable.",
	},
	{
		id = "valkyra_gts", name = "Valkyra GT-S", brand = "Valkyra", class = "S1",
		price = 480000, topSpeedMph = 211, power = 80, grip = 1.42, brake = 108,
		drive = "AWD", bodyStyle = "super", spoiler = false,
		defaultColor = Color3.fromRGB(150, 160, 176),
		description = "Cold, clinical speed. German engineering at full send.",
	},
	{
		id = "nightfall_lm", name = "Nightfall LM", brand = "Nightfall", class = "S1",
		price = 510000, topSpeedMph = 208, power = 82, grip = 1.46, brake = 110,
		drive = "RWD", bodyStyle = "super", spoiler = true,
		defaultColor = Color3.fromRGB(16, 18, 30),
		description = "A road-legal endurance racer that never really left Le Mans.",
	},
	-- ============================== S2 CLASS ==============================
	{
		id = "apex_panther", name = "Apex Panther", brand = "Apex", class = "S2",
		price = 1250000, topSpeedMph = 245, power = 90, grip = 1.52, brake = 118,
		drive = "AWD", bodyStyle = "hyper", spoiler = true,
		defaultColor = Color3.fromRGB(12, 108, 92),
		description = "A hypercar with claws. The festival poster car.",
	},
	{
		id = "solstice_w1", name = "Solstice W1", brand = "Solstice", class = "S2",
		price = 1400000, topSpeedMph = 250, power = 88, grip = 1.50, brake = 116,
		drive = "AWD", bodyStyle = "hyper", spoiler = false,
		defaultColor = Color3.fromRGB(244, 246, 250),
		description = "Sixteen cylinders of pure horizon-chasing luxury.",
	},
	{
		id = "eclipse_r", name = "Eclipse R Evo", brand = "Eclipse", class = "S2",
		price = 1100000, topSpeedMph = 238, power = 92, grip = 1.58, brake = 122,
		drive = "AWD", bodyStyle = "hyper", spoiler = true,
		defaultColor = Color3.fromRGB(88, 12, 140),
		description = "Track weapon with a license plate. Downforce for days.",
	},
	-- ============================== X CLASS ==============================
	{
		id = "regalia_f1x", name = "Regalia F1-X", brand = "Regalia", class = "X",
		price = 2800000, topSpeedMph = 273, power = 98, grip = 1.62, brake = 126,
		drive = "RWD", bodyStyle = "hyper", spoiler = true,
		defaultColor = Color3.fromRGB(230, 178, 60),
		description = "The nineties icon. Center seat, gold bay, no equal.",
	},
	{
		id = "zenith_prime", name = "Zenith Apex Prime", brand = "Zenith", class = "X",
		price = 3200000, topSpeedMph = 281, power = 104, grip = 1.68, brake = 132,
		drive = "AWD", bodyStyle = "hyper", spoiler = true,
		defaultColor = Color3.fromRGB(10, 132, 255),
		description = "The fastest thing at the festival. End of discussion.",
	},
}

CarCatalog.ById = {} :: { [string]: CarDef }
for _, car in CarCatalog.Cars do
	CarCatalog.ById[car.id] = car
end

function CarCatalog.Get(id: string): CarDef?
	return CarCatalog.ById[id]
end

return CarCatalog

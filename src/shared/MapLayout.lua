--!strict
-- Shared map geometry constants used by the world builder, races and the minimap.

local MapLayout = {
	-- Half size of the playable square, in studs (map spans -HalfSize..HalfSize)
	MapHalfSize = 1024,

	-- The main "Horizon" ring highway
	RingRadius = 500,
	RoadWidth = 26,
	RoadY = 1, -- top surface height of all roads

	-- Festival hub in the middle of the map
	HubRadius = 130,
	HubPosition = Vector3.new(0, 1, 0),

	-- Dealership showroom (inside the hub, east side)
	DealershipPosition = Vector3.new(150, 1, -55),

	-- Lake south-east
	LakeCenter = Vector3.new(330, 0, -330),
	LakeRadius = 140,
	WaterLevel = -5,
}

return MapLayout

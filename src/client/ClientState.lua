--!strict
-- Client-side cache of the player's profile (credits, owned cars, paint),
-- kept in sync by the server's ProfileUpdate remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

export type ProfileSnapshot = {
	credits: number,
	owned: { [string]: boolean },
	colors: { [string]: { number } },
	activeCar: string?,
}

local ClientState = {}

ClientState.Profile = {
	credits = 0,
	owned = {},
	colors = {},
	activeCar = nil,
} :: ProfileSnapshot

ClientState.ProfileChanged = Instance.new("BindableEvent")

function ClientState.Init()
	local profileUpdate = Remotes.Get("ProfileUpdate") :: RemoteEvent
	profileUpdate.OnClientEvent:Connect(function(snapshot)
		if type(snapshot) == "table" then
			ClientState.Profile = snapshot
			ClientState.ProfileChanged:Fire()
		end
	end)
end

function ClientState.Owns(carId: string): boolean
	return ClientState.Profile.owned[carId] == true
end

return ClientState

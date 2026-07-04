--!strict
-- ForzaBlox server bootstrap.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

Remotes.Init()

local LightingSetup = require(script.LightingSetup)
local MapBuilder = require(script.MapBuilder)
local DealershipBuilder = require(script.DealershipBuilder)
local EconomyService = require(script.EconomyService)
local CarService = require(script.CarService)
local RaceService = require(script.RaceService)

LightingSetup.Apply()
MapBuilder.Build()
DealershipBuilder.Build()

EconomyService.Init()
CarService.Init(EconomyService)
RaceService.Init(EconomyService, CarService)

print("[ForzaBlox] Server ready — welcome to the festival!")

--!strict
-- ForzaBlox client bootstrap.

local ClientState = require(script.ClientState)
local CarController = require(script.CarController)
local ChaseCamera = require(script.ChaseCamera)

local UI = script.UI
local Notifications = require(UI.Notifications)
local HUD = require(UI.HUD)
local DealershipUI = require(UI.DealershipUI)
local GarageUI = require(UI.GarageUI)
local RaceUI = require(UI.RaceUI)

ClientState.Init()
CarController.Start()
ChaseCamera.Start()

Notifications.Start()
HUD.Start()
DealershipUI.Start()
GarageUI.Start()
RaceUI.Start()

print("[ForzaBlox] Client ready")

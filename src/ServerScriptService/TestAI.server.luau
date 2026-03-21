--!strict

local ServerStorage = game:GetService("ServerStorage")

local VluxyAI = ServerStorage.VluxyAI

local BasicKillerStates = require(VluxyAI.States.BasicKiller)

local Builder = require(VluxyAI.Builders.SPSMBuilder)

local entity = workspace:FindFirstChild("Rig") :: Model

--
local ai = Builder.new(entity)

ai:SetStateData(BasicKillerStates.new(entity))

ai:Build():Start()

--pathfinding
-- local pathfinder = RobloxPathfinding.new(entity)
-- 	:SetAgentSettings({
-- 		AgentRadius = 2,
-- 		WaypointSpacing = 2,
-- 	})
-- 	:SetPathSettings({
-- 		EntitySpeed = 8,
-- 		VisualizePath = true,
-- 		PathingUpdateSpeed = 0.25,
-- 		PredictTargetPosition = false,
-- 		ShaveDownWaypoints = true,
-- 	})

-- pathfinder:Run()

-- while task.wait() do
-- 	local player = Players:GetPlayers()[1] :: Player?
-- 	local character = player and player.Character
-- 	if player and character then
-- 		local player = Players:GetPlayers()[1]
-- 		pathfinder:MoveTo(character.PrimaryPart.Position)
-- 	end
-- end

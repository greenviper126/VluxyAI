--!strict

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

--local Builder = require(ServerStorage["FSM-AI"].Builder)
local RobloxPathfinding = require(ServerStorage.VluxyAI.Pathfinding.RobloxPathfinding)

--local States = ServerStorage["FSM-AI"].States

local entity = workspace:FindFirstChild("Rig") :: Model
local target = workspace:FindFirstChild("Target") :: BasePart

-- local ai = Builder.new(entity)

-- ai:SetFallbackState("Idle")

-- ai:SetState("Idle", require(States.Idle))

-- ai:Build():Start()

for _, child in pairs(entity:GetChildren()) do
	if child:IsA("BasePart") then
		child:SetNetworkOwner(nil)
	end
end

local pathfinder = RobloxPathfinding.new(entity)
	:SetAgentSettings({
		AgentRadius = 2,
		WaypointSpacing = 2,
	})
	:SetPathSettings({
		EntitySpeed = 8,
		VisualizePath = true,
		PathingUpdateSpeed = 0.25,
		PredictTargetPosition = false,
		ShaveDownWaypoints = true,
	})

pathfinder:Run()

while task.wait() do
	local player = Players:GetPlayers()[1] :: Player?
	local character = player and player.Character
	if player and character then
		local player = Players:GetPlayers()[1]
		pathfinder:MoveTo(character.PrimaryPart.Position)
	end
end

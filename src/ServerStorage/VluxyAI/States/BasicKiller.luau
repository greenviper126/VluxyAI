--!strict

local VluxyAI = script.Parent.Parent

local SPSMBuilder = require(VluxyAI.Builders.SPSMBuilder)

------------------------------------------------------------------------------------------------------------------------

type States = {
	Init: SPSMBuilder.State<self>,
	Idle: SPSMBuilder.State<self>,
	Target: SPSMBuilder.State<self>,
}

type self = SPSMBuilder.StandardStater & {
	states: States,
	data: {},
}

------------------------------------------------------------------------------------------------------------------------

local States = {
	Init = {},
	Idle = {},
	Target = {},
} :: States

------------------------------------------------------------------------------------------------------------------------

function States.Init.Start(self)
	self.fallbackState = "Idle"

	self.pathfinder:SetAgentSettings({
		AgentRadius = 2,
		WaypointSpacing = 2,
	})

	self.pathfinder:SetPathSettings({
		EntitySpeed = 8,
		VisualizePath = true,
		PathingUpdateSpeed = 0.25,
		PredictTargetPosition = false,
		ShaveDownWaypoints = true,
	})
end

function States.Init.Update(self)
	return self.fallbackState
end

------------------------------------------------------------------------------------------------------------------------

function States.Idle.Start(self)
	print("Starting Idle State")

	self.pathfinder:Toggle(false)
end

function States.Idle.Update(self)
	print("Updating Idle State")

	local player, _dist = self.targetingBaseAgent:NearestPlayerInBounds(15)

	if player then
		local root = self.targetingBaseAgent:GetAliveRootFromPlayer(player)
		if not root then
			return nil
		end
		local isSpotted = self.perceptionAgent:AgentSeesPosition(root.Position)
		if not isSpotted then
			return nil
		end

		self.perceptionAgent:SetTarget(root)

		return "Target"
	else
		return nil
	end
end

------------------------------------------------------------------------------------------------------------------------

function States.Target.Start(self)
	print("Starting Target State")

	self.pathfinder:Toggle(true)
end

function States.Target.Update(self)
	if not self.perceptionAgent._target then
		return "Idle"
	end

	if not self.perceptionAgent:AgentSeesTarget() then
		return "Idle"
	end

	self.pathfinder:MoveTo(self.perceptionAgent._target.Position)

	return nil
end

function States.Target.End(self)
	print("Ending Target State")

	self.pathfinder:Toggle(false)
end

------------------------------------------------------------------------------------------------------------------------

return States

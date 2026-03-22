--!strict

--[[
	Note:
	Some types here can be simplified after testing.

	How the constructor works internally is subject to change.

	Decided to not separate state logic from transition logic as a new FSM system can just be made later; we use a more traditional FSM here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

local VluxyAI = script.Parent.Parent

local RobloxPathfinding = require(VluxyAI.Pathfinding.RobloxPathfinding)

local EnvironmentBaseAgent = require(ServerStorage.VluxyAI.BaseAgents.EnvironmentBaseAgent)
local TargetingBaseAgent = require(ServerStorage.VluxyAI.BaseAgents.TargetingBaseAgent)

local PerceptionAgent = require(VluxyAI.Agents.PerceptionAgent)
local SpatialAgent = require(VluxyAI.Agents.SpatialAgent)

------------------------------------------------------------------------------------------------------------------------

type State = {
	Start: (self: self) -> (),
	Update: (self: self) -> string?,
	End: (self: self) -> (),
}

type States = {
	Idle: State,
	Target: State,
}

type self = {
	environmentBaseAgent: EnvironmentBaseAgent.Environment,
	targetingBaseAgent: TargetingBaseAgent.Targeting,

	perceptionAgent: PerceptionAgent.Perception,
	spatialAgent: SpatialAgent.Spatial,

	pathfinder: RobloxPathfinding.Pathfinding,

	states: States,
	data: { [string]: any },

	fallbackState: string,

	_cleaner: typeof(Trove.new()),
}

------------------------------------------------------------------------------------------------------------------------

local States = {} :: States

States.Idle = {
	Start = function(self)
		print("Starting Idle State")

		self.pathfinder:Toggle(false)
	end,

	Update = function(self)
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
	end,

	End = function(self)
		print("Ending Idle State")
	end,
}

States.Target = {
	Start = function(self)
		print("Starting Target State")

		self.pathfinder:Toggle(true)
	end,

	Update = function(self)
		if not self.perceptionAgent._target then
			return "Idle"
		end

		if not self.perceptionAgent:AgentSeesTarget() then
			return "Idle"
		end

		self.pathfinder:MoveTo(self.perceptionAgent._target.Position)

		return nil
	end,

	End = function(self)
		print("Ending Target State")

		self.pathfinder:Toggle(false)
	end,
}

------------------------------------------------------------------------------------------------------------------------

local function deepClone(t)
	local clone = {}
	for k, v in t do
		clone[k] = type(v) == "table" and deepClone(v) or v
	end
	return clone
end

--[[
	Basic Killer FSM Entity.
]]
local BasicKiller = {}

function BasicKiller.new(entity: Model): self
	local self = {}
	self._cleaner = Trove.new()

	self.fallbackState = "Idle"

	self.states = deepClone(States)
	self.data = {}

	--agents
	self.environmentBaseAgent = EnvironmentBaseAgent.new(entity)
	self.targetingBaseAgent = TargetingBaseAgent.new(entity)

	self.spatialAgent = SpatialAgent.new(entity, self.environmentBaseAgent)
	self.perceptionAgent = PerceptionAgent.new(entity, self.environmentBaseAgent)

	self.environmentBaseAgent:SetAgentNetworkOwner(nil)
	self.environmentBaseAgent:SetAgentCollisionGroup("Default")

	--pathfinding
	self.pathfinder = RobloxPathfinding.new(entity)
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

	--cleanup
	self._cleaner:Add(self.environmentBaseAgent._cleaner)
	self._cleaner:Add(self.targetingBaseAgent._cleaner)

	self._cleaner:Add(self.perceptionAgent._cleaner)
	self._cleaner:Add(self.spatialAgent._cleaner)

	self._cleaner:Add(self.pathfinder._cleaner)

	return self
end

return BasicKiller

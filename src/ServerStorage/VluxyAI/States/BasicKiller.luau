--!strict

--[[
	Note:
	Some types here can be simplified after testing.

	How the constructor works internally is subject to change.

	Decided to not separate state logic from transition logic as a new FSM system can just be made later; we use a more traditional FSM here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

local VluxyAI = script.Parent.Parent

local RobloxPathfinding = require(VluxyAI.Pathfinding.RobloxPathfinding)

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
	Walk: State,
}

type self = {
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
	end,

	Update = function(self)
		print("Updating Idle State")

		local shouldWalk = math.random(0, 99) < 5
		return shouldWalk and "Walk" or nil
	end,

	End = function(self)
		print("Ending Idle State")
	end,
}

States.Walk = {
	Start = function(self)
		print("Starting Walk State")

		self.pathfinder:Toggle(true)
	end,

	Update = function(self)
		if self.pathfinder:GoalMagnitude() < 5 then
			local currentPosition = self.spatialAgent.primary.Position
			local newPosition = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))

			self.pathfinder:MoveTo(currentPosition + newPosition)
		end

		local shouldIdle = math.random(0, 99) < 10
		return shouldIdle and "Idle" or nil
	end,

	End = function(self)
		print("Ending Walk State")

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
	self.spatialAgent = SpatialAgent.new(entity)
	self.perceptionAgent = PerceptionAgent.new(entity)

	self.perceptionAgent:SetAgentNetworkOwner(nil)
	self.perceptionAgent:SetAgentCollisionGroup("Default")

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
	self._cleaner:Add(self.perceptionAgent._cleaner)
	self._cleaner:Add(self.spatialAgent._cleaner)
	self._cleaner:Add(self.pathfinder._cleaner)

	return self
end

return BasicKiller

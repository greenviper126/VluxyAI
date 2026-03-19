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
	PerceptionAgent: PerceptionAgent.Perception,
	SpatialAgent: SpatialAgent.Spatial,

	Pathfinder: RobloxPathfinding.Pathfinding,

	States: States,
	Data: { [string]: any },

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

		return nil
	end,

	End = function(self)
		print("Ending Idle State")
	end,
}

States.Walk = {
	Start = function(self)
		print("Starting Walk State")
	end,

	Update = function(self)
		print("Updating Walk State")

		return nil
	end,

	End = function(self)
		print("Ending Walk State")
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

	self.PerceptionAgent = PerceptionAgent.new(entity)
	self.SpatialAgent = SpatialAgent.new(entity)

	self.Pathfinder = RobloxPathfinding.new(entity)

	self.States = deepClone(States)
	self.Data = {}

	--cleanup
	self._cleaner:Add(self.PerceptionAgent._cleaner)
	self._cleaner:Add(self.SpatialAgent._cleaner)
	self._cleaner:Add(self.Pathfinder._cleaner)

	return self
end

return BasicKiller

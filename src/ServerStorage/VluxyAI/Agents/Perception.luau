--!strict

local DEFAULT_PERCEPTION_SETTINGS: SetPerceptionSettings = {
	VisualRange = 10,
}

------------------------------------------------------------------------------------------------------------------------

type BasePerceptionSettings<N> = {
	VisualRange: N,
}

export type SetPerceptionSettings = BasePerceptionSettings<number>

------------------------------------------------------------------------------------------------------------------------

table.freeze(DEFAULT_PERCEPTION_SETTINGS)

------------------------------------------------------------------------------------------------------------------------

local Environment = require(script.Parent.Parent.BaseAgents.Environment)

------------------------------------------------------------------------------------------------------------------------

--[[
	Perception class for agents, responsible for determining what the agent can see and perceive in the environment.
	Inherits from Environment to utilize common functionality and properties related to the agent's entity.
]]
local Perception = {}
Perception.__index = Perception
setmetatable(Perception, Environment)

type self = {
	_target: BasePart?,

	_visualRange: number,
}

export type Perception = typeof(setmetatable({} :: self, Perception)) & Environment.Environment

--[[
	Constructor for Perception class

	@param entity Model - the entity

	@return Perception - An instance of the Perception class initialized with the given entity.
]]
function Perception.new(entity: Model): Perception
	local self = setmetatable(Environment.new(entity) :: Perception, Perception)

	self._target = nil

	self._visualRange = DEFAULT_PERCEPTION_SETTINGS.VisualRange

	return self
end

--[[
	Sets the target for the agent's perception. This is the BasePart that the agent will attempt to perceive and interact with.

	@param self Perception - the object
	@param target BasePart? - the BasePart to set as the target, or nil to clear the target
]]
function Perception.SetTarget(self: Perception, target: BasePart?)
	self._target = target
end

--[[
	Sets the visual perception range for the agent.

	@param self Perception - the object
	@param range number? - optional visual range to set (defaults to 10 if not provided)
]]
function Perception.SetPerceptionRange(self: Perception, range: number?)
	self._visualRange = range or DEFAULT_PERCEPTION_SETTINGS.VisualRange
end

--[[
	Is the target in line of sight with no obstructions?

	@param self Perception - the object

	@return boolean - True if the agent can see the target without obstructions, false otherwise.
]]
function Perception.AgentSeesTarget(self: Perception): boolean
	if not self._target then
		return false
	end

	local result = self:Obstructed(self._target.Position)
	local inSight, _product = self:PosInSightOfCord(self.primary.CFrame, self._target.Position, self._visualRange)

	if not result and inSight then
		return true
	else
		return false
	end
end

--[[
	Is position in line of sight with no obstructions?

	@param self Perception - the object
	@param position Vector3 - the position to check visibility for

	@return boolean - True if the agent can see the position without obstructions, false otherwise.
]]
function Perception.AgentSeesPosition(self: Perception, position: Vector3): boolean
	local result = self:Obstructed(position)
	local inSight, _product = self:PosInSightOfCord(self.primary.CFrame, position, self._visualRange)

	if not result and inSight then
		return true
	else
		return false
	end
end

--[[
	Is agent in line of sight of the target with no obstructions?

	@param self Perception - the object

	@return boolean - True if the target can see the agent without obstructions, false otherwise.
]]
function Perception.TargetSeesAgent(self: Perception): boolean
	if not self._target then
		return false
	end

	local result = self:Obstructed(self._target.Position)
	local inSight, _product = self:PosInSightOfCord(self._target.CFrame, self.primary.Position, self._visualRange)

	if not result and inSight then
		return true
	else
		return false
	end
end

--[[
	Checks if any set of players can see the agent without obstructions.

	@param self Perception - the object
	@param parts { BasePart } - a list of BasePart instances to check for visibility against (e.g., player character parts)

	@return { BasePart } - A list of player root parts that can see the agent.
]]
function Perception.PartsSeeAgent(self: Perception, parts: { BasePart }): { BasePart }
	local roots = {}

	for _, root in ipairs(parts) do
		local inSight, _product = self:PosInSightOfCord(root.CFrame, self.primary.Position, self._visualRange)
		local result = self:Obstructed(root.Position)

		if not result and inSight then
			table.insert(roots, root)
		end
	end

	return roots
end

return Perception

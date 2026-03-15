--!strict

export type CastingTypes = "Agents" | "Players" | "Both"
type CastingInput = CastingTypes | RaycastParams

------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

------------------------------------------------------------------------------------------------------------------------

--[[
	Base class for agent environments, providing common functionality for observation and action classes.
]]
local Environment = {}
Environment.__index = Environment

type self = {
	entity: Model,
	primary: BasePart,
	humanoid: Humanoid,

	_cleaner: typeof(Trove.new()),
}

export type Environment = typeof(setmetatable({} :: self, Environment))

--[[
	constructor for Environment class

	@param entity Model - the entity

	@return Environment An instance of the Environment class initialized with the given entity.
]]
function Environment.new(entity: Model): Environment
	local primary = entity.PrimaryPart
	local humanoid = entity:FindFirstChildOfClass("Humanoid")

	assert(primary, "Entity must have a PrimaryPart! " .. entity:GetFullName())
	assert(humanoid, "Entity must have a Humanoid! " .. entity:GetFullName())

	local self = setmetatable({} :: self, Environment)
	self._cleaner = Trove.new()

	self.entity = entity
	self.primary = primary
	self.humanoid = humanoid

	return self
end

--[[
	Returns all the BasePart instances that are part of the agent entity.

	@param self Environment - the object

	@return { BasePart } A list of BasePart instances belonging to the agent.
]]
function Environment.GetAgentParts(self: Environment): { BasePart }
	return self.entity:QueryDescendants("BasePart")
end

--[[
	Returns the PrimaryPart of the agent entity, if it exists.
	
	@param self Environment - the object

	@return { BasePart } A list containing the PrimaryParts of all player characters.
]]
function Environment.GetPlayerRoots(self: Environment): { BasePart }
	local roots = {}

	for _, player in pairs(Players:GetPlayers()) do
		if not player.Character then
			continue
		end

		local primary = player.Character.PrimaryPart
		if not primary then
			continue
		end

		table.insert(roots, primary)
	end

	return roots
end

--[[
	Returns all the BasePart instances that are part of all player characters.
	
	@param self Environment - the object

	@return { BasePart } A list of BasePart instances belonging to all player characters.
]]
function Environment.GetPlayerParts(self: Environment): { BasePart }
	local parts = {}

	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end

		local playerParts = character:QueryDescendants("BasePart") :: { BasePart }
		for _, part in pairs(playerParts) do
			table.insert(parts, part)
		end
	end

	return parts
end

--[[
	Sets the collision group of all parts of the agent to the specified group.

	@param self Environment - the object
	@param group string - the name of the collision group to set for the agent's parts.
]]
function Environment.SetAgentCollisionGroup(self: Environment, group: string)
	for _, part in ipairs(self:GetAgentParts()) do
		part.CollisionGroup = group
	end
end

--[[
	Sets the network ownership of all parts of the agent to the specified player.

	@param self Environment - the object
	@param networkOwner Player? - the Player instance to set as the network owner, or nil to set no owner.
]]
function Environment.SetAgentNetworkOwner(self: Environment, networkOwner: Player?)
	for _, part in ipairs(self:GetAgentParts()) do
		part:SetNetworkOwner(networkOwner)
	end
end

--[[
	Generates RaycastParams to ignore certain sets of objects based on the specified type.

	@param self Environment - the object
	@param paramType CastingTypes - a string indicating which types of objects to ignore ("Agents", "Players", or "Both")

	@return RaycastParams configured to ignore the specified types of objects.
]]
function Environment.AvoidParams(self: Environment, paramType: CastingTypes): RaycastParams
	local params = RaycastParams.new()
	params.IgnoreWater = true
	params.FilterType = Enum.RaycastFilterType.Exclude

	local function append(a: { any }, b: { any }): { any }
		return table.move(b, 1, #b, #a + 1, a)
	end

	if paramType == "Agents" then
		params.FilterDescendantsInstances = self:GetAgentParts() :: { any }
	elseif paramType == "Players" then
		params.FilterDescendantsInstances = self:GetPlayerParts() :: { any }
	elseif paramType == "Both" then
		local agentParts = self:GetAgentParts()
		local playerParts = self:GetPlayerParts()
		local result = append(agentParts, playerParts)

		params.FilterDescendantsInstances = result
	end

	return params
end

--[[
	Checks if the path to a position is obstructed based on the given parameters.

	@param position Vector3 - The target position to check obstruction for.
	@param paramType CastingInput? - Optional. Can be a CastingTypes string or RaycastParams. Defaults to "Both".

	@return RaycastResult? The result of the raycast, or nil if unobstructed.
]]
function Environment.Obstructed(self: Environment, position: Vector3, paramType: CastingInput?): RaycastResult?
	local params: RaycastParams

	if typeof(paramType) == "string" then
		params = self:AvoidParams(paramType)
	elseif typeof(paramType) == "RaycastParams" then
		params = paramType
	else
		params = self:AvoidParams("Both")
	end

	local direction = (position - self.primary.Position) -- keep magnitude
	return workspace:Raycast(self.primary.Position, direction, params)
end

--[[
	Cleans up the object.

	@param self Environment - the object
]]
function Environment.Cleanup(self: Environment)
	self._cleaner:Destroy()
end

return Environment

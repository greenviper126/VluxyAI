--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_SPATIAL_SETTINGS: SetSpatialSettings = {
	CollisionsRays = 8,
	CollisionDistance = 100,
	SpreadDistance = 6,
	VisualRange = 10,
}

------------------------------------------------------------------------------------------------------------------------

type BaseSpatialSettings<N> = {
	CollisionsRays: N,
	CollisionDistance: N,
	SpreadDistance: N,
	VisualRange: N,
}

export type SetSpatialSettings = BaseSpatialSettings<number>

------------------------------------------------------------------------------------------------------------------------

table.freeze(DEFAULT_SPATIAL_SETTINGS)

------------------------------------------------------------------------------------------------------------------------

local Trove = require(ReplicatedStorage.Packages.trove)

local vluxyAI = script.Parent.Parent

local EnvironmentBaseAgent = require(vluxyAI.BaseAgents.EnvironmentBaseAgent)

local random = Random.new()

------------------------------------------------------------------------------------------------------------------------

local Spatial = {}
Spatial.__index = Spatial

Spatial.Roots = {} :: { BasePart } --read only

type self = {
	entity: Model,

	spatialSettings: SetSpatialSettings,

	_environmentBaseAgent: EnvironmentBaseAgent.Environment,

	_cleaner: typeof(Trove.new()),
}

export type Spatial = typeof(setmetatable({} :: self, Spatial))

--[[
	Constructor for Spatial class

	@param entity Model - the entity

	@return Spatial - An instance of the Spatial class initialized with the given entity.
]]
function Spatial.new(entity: Model, environmentBaseAgent: EnvironmentBaseAgent.Environment): Spatial
	local self = setmetatable({} :: self, Spatial)
	self._cleaner = Trove.new()

	self._environmentBaseAgent = environmentBaseAgent

	self.entity = entity

	local exists = table.find(Spatial.Roots, self._environmentBaseAgent.primary)
	if not exists then
		table.insert(Spatial.Roots, self._environmentBaseAgent.primary)
	end

	self._cleaner:Add(function()
		local index = table.find(Spatial.Roots, self._environmentBaseAgent.primary)
		if index then
			table.remove(Spatial.Roots, index)
		end
	end)

	self.spatialSettings = table.clone(DEFAULT_SPATIAL_SETTINGS)

	return self
end

--[[
    Sets the spatial settings for the agent, allowing customization of collision rays, distances, and visual range.

    @param self Spatial - the object
    @param spatialSettings SetSpatialSettings? - a table containing the spatial settings to apply. If nil, defaults will be used.

    @return Spatial - returns the instance of the Spatial class with updated settings.
]]
function Spatial.SetSpatialSettings(self: Spatial, spatialSettings: SetSpatialSettings?): Spatial
	if not spatialSettings then
		self.spatialSettings = table.clone(DEFAULT_SPATIAL_SETTINGS)
		return self
	end

	for k: string, v in pairs(spatialSettings) do
		if DEFAULT_SPATIAL_SETTINGS[k] == nil then
			warn("Invalid spatial setting named " .. k .. "!", self.entity:GetFullName())
			continue
		end

		self.spatialSettings[k] = v
	end

	return self
end

function Spatial.CalcCollisionSpeed(
	self: Spatial,
	currentSpeed: number,
	maxSpeed: number,
	spreadDistance: number?
): number
	local spreadDist = spreadDistance or self.spatialSettings.SpreadDistance

	local part, vectorAB = self:ClosestPart(Spatial.Roots)

	local adjust = random:NextNumber() * 0.3
	if not part or not vectorAB or (vectorAB.Magnitude > spreadDist) then
		return currentSpeed + (maxSpeed - currentSpeed) * adjust
	end
	local _inSight, product = self._environmentBaseAgent:PosInSightOfCord(
		self._environmentBaseAgent.primary.CFrame,
		part.Position,
		self.spatialSettings.VisualRange
	)
	local percent = (1 - product) / 2
	local speed = maxSpeed * percent

	return currentSpeed + (speed - currentSpeed) * adjust
end

--[[
    Is agent close to collidable object?
    
    @param self Spatial - the object
    @param maxCollisionRays number? - the number of rays to cast around the agent to check for obstacles.
    @param maxDistance number? - optional maximum distance to check for obstacles.
    
    @return RaycastResult? - the result of the raycast if an obstacle is detected, or nil if no obstacles are detected within range.
]]
function Spatial.CloseToObject(self: Spatial, maxCollisionRays: number?, maxDistance: number?): RaycastResult?
	local collisionRays = maxCollisionRays or self.spatialSettings.CollisionsRays
	local distance = maxDistance or self.spatialSettings.CollisionDistance

	local params = self._environmentBaseAgent:AvoidParams("Both")
	local radiansPerRay = (math.pi * 2) / collisionRays
	for i = 1, collisionRays do
		local direction = Vector3.new(math.cos(radiansPerRay * i), 0, math.sin(radiansPerRay * i))
		local ray = workspace:Raycast(self._environmentBaseAgent.primary.Position, direction * distance, params)
		if ray then
			return ray
		end
	end

	return nil
end

--[[
    Direction that has the most distance/space from the others.

    @param self Spatial - the object
    @param maxCollisionRays number? - the number of rays to cast around the agent to check for obstacles.
    @param maxDistance number? - optional maximum distance to check for obstacles.

    @return Vector3 - the direction vector representing the most open direction for the agent to move towards
    @return number - the distance to the nearest obstacle in that direction (or maxDistance if no obstacles are detected within range)
]]
function Spatial.OpenDirection(self: Spatial, maxCollisionRays: number?, maxDistance: number?): (Vector3, number)
	local collisionRays = maxCollisionRays or self.spatialSettings.CollisionsRays
	local distance = maxDistance or self.spatialSettings.CollisionDistance

	local bestDirection, bestDist = nil, 0

	local params = self._environmentBaseAgent:AvoidParams("Both")
	local radiansPerRay = (math.pi * 2) / collisionRays

	for i = 1, collisionRays do
		local direction = Vector3.new(math.cos(radiansPerRay * i), 0, math.sin(radiansPerRay * i))
		local ray = workspace:Raycast(self._environmentBaseAgent.primary.Position, direction * distance, params)

		if ray then
			if ray.Distance < bestDist then
				continue
			end
			bestDist = ray.Distance
			bestDirection = direction
		else
			bestDist = distance
			bestDirection = direction
		end
	end

	return bestDirection, bestDist
end

--[[
    Finds the closest part from a list of parts and returns that part along with the vector from the agent to that part.

    @param self Spatial - the object
    @param parts { BasePart } - a list of BasePart instances to check against

    @return BasePart? - the closest part found in the list, or nil if no parts are provided
    @return Vector3? - the vector from the agent's primary part to the closest part, or nil if no parts are provided
]]
function Spatial.ClosestPart(self: Spatial, parts: { BasePart }): (BasePart?, Vector3?)
	local bestPart, bestVector = nil, Vector3.new(1, 1, 1) * math.huge

	local agentParts = self._environmentBaseAgent:GetAgentParts()

	for _, part in pairs(parts) do
		if table.find(agentParts, part) then
			continue
		end --exclude agent parts from table

		local vectorAB = (part.Position - self._environmentBaseAgent.primary.Position)
		if vectorAB.Magnitude < bestVector.Magnitude then
			bestPart, bestVector = part, vectorAB
		end
	end

	return bestPart, bestVector
end

--[[
	Cleans up the object.

	@param self Spatial - the object
]]
function Spatial.Cleanup(self: Spatial)
	self._cleaner:Destroy()
end

return Spatial

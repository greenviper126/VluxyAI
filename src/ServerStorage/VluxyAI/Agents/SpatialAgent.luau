--!strict

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

local EnvironmentBaseAgent = require(script.Parent.Parent.BaseAgents.EnvironmentBaseAgent)

local random = Random.new()

------------------------------------------------------------------------------------------------------------------------

local Spatial = {}
Spatial.__index = Spatial

Spatial.Roots = {} :: { BasePart } --read only

type self = {
	spatialSettings: SetSpatialSettings,
}

export type Spatial = typeof(setmetatable({} :: self, Spatial)) & EnvironmentBaseAgent.Environment

--[[
	Constructor for Spatial class

	@param entity Model - the entity

	@return Spatial - An instance of the Spatial class initialized with the given entity.
]]
function Spatial.new(entity: Model): Spatial
	setmetatable(Spatial, EnvironmentBaseAgent)
	local self = setmetatable(EnvironmentBaseAgent.new(entity) :: Spatial, Spatial)

	local exists = table.find(Spatial.Roots, self.primary)
	if not exists then
		table.insert(Spatial.Roots, self.primary)
	end

	self._cleaner:Add(function()
		local index = table.find(Spatial.Roots, self.primary)
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
	local _inSight, product =
		self:PosInSightOfCord(self.primary.CFrame, part.Position, self.spatialSettings.VisualRange)
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

	local params = self:AvoidParams("Both")
	local radiansPerRay = (math.pi * 2) / collisionRays
	for i = 1, collisionRays do
		local direction = Vector3.new(math.cos(radiansPerRay * i), 0, math.sin(radiansPerRay * i))
		local ray = workspace:Raycast(self.primary.Position, direction * distance, params)
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

	local params = self:AvoidParams("Both")
	local radiansPerRay = (math.pi * 2) / collisionRays

	for i = 1, collisionRays do
		local direction = Vector3.new(math.cos(radiansPerRay * i), 0, math.sin(radiansPerRay * i))
		local ray = workspace:Raycast(self.primary.Position, direction * distance, params)

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

	local agentParts = self:GetAgentParts()

	for _, part in pairs(parts) do
		if table.find(agentParts, part) then
			continue
		end --exclude agent parts from table

		local vectorAB = (part.Position - self.primary.Position)
		if vectorAB.Magnitude < bestVector.Magnitude then
			bestPart, bestVector = part, vectorAB
		end
	end

	return bestPart, bestVector
end

return Spatial

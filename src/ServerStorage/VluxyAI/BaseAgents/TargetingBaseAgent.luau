--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

------------------------------------------------------------------------------------------------------------------------

--[[
	Base class for agent Targeting, providing common functionality for observation and action classes.
]]
local Targeting = {}
Targeting.__index = Targeting

type self = {
	entity: Model,
	primary: BasePart,

	_cleaner: typeof(Trove.new()),
}

export type Targeting = typeof(setmetatable({} :: self, Targeting))

--[[
	constructor for Targeting class

	@param entity Model - the entity

	@return Targeting An instance of the Targeting class initialized with the given entity.
]]
function Targeting.new(entity: Model): Targeting
	local primary = entity.PrimaryPart

	assert(primary, "Entity must have a PrimaryPart! " .. entity:GetFullName())

	local self = setmetatable({} :: self, Targeting)
	self._cleaner = Trove.new()

	self.entity = entity
	self.primary = primary

	return self
end

--[[
	Returns the PrimaryPart of all alive player characters, if they exist.
	
	@param self Targeting - the object

	@return { BasePart } A list containing the PrimaryParts of all alive player characters.
]]
function Targeting.GetAlivePlayerRoots(self: Targeting): { BasePart }
	local roots = {}

	for _, player in pairs(Players:GetPlayers()) do
		if not player.Character then
			continue
		end
		if not self:PlayerIsAlive(player) then
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
	Returns all the BasePart instances that are part of all alive player characters.
	
	@param self Targeting - the object

	@return { BasePart } A list of BasePart instances belonging to all alive player characters.
]]
function Targeting.GetAlivePlayerParts(self: Targeting): { BasePart }
	local parts = {}

	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		if not self:PlayerIsAlive(player) then
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
    Checks if a player is considered alive.

    @param self Targeting - the object
    @param player Player - the player to check

    @return boolean - True if the player is considered alive, false otherwise.
]]
function Targeting.PlayerIsAlive(self: Targeting, player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return false
	end

	return hum.Health > 0
end

--[[
    Calculates the distance from a player to the entity or a given position.

    @param self Targeting - the object
    @param player Player - the player to calculate distance for
    @param position Vector3? - the position to calculate distance to, or nil to use the entity's current position

    @return number - the distance from the player to the position, or math.huge if the player is not alive or has no character.
]]
function Targeting.Distance(self: Targeting, player: Player, position: Vector3?): number
	if not player.Character or not self:PlayerIsAlive(player) then
		return math.huge
	end

	local root = player.Character.PrimaryPart :: BasePart
	if not root then
		return math.huge
	end

	local origin = position or self.primary.Position
	return (origin - root.Position).Magnitude
end

--[[
    Finds the nearest player to a given position.

    @param self Targeting - the object
    @param position Vector3? - the position to check from, or nil to use the entity's current position

    @return Player? - the nearest player, or nil if there are no players
    @return number - the distance to the nearest player, or math.huge if there are no players
]]
function Targeting.NearestPlayer(self: Targeting, position: Vector3?): (Player?, number)
	local bestPlayer, bestDist = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local distance = self:Distance(player, position or self.primary.Position)

		if distance < bestDist then
			bestDist = distance
			bestPlayer = player
		end
	end

	return bestPlayer, bestDist
end

--[[
    Finds the nearest player to a given position within a specified distance.

    @param self Targeting - the object
    @param bounds number - the maximum distance to consider for nearby players
    @param position Vector3? - the position to check from, or nil to use the entity's current position

    @return Player? - the nearest player within bounds, or nil if no players are within bounds
    @return number - the distance to the nearest player, or math.huge if no players are within bounds
]]
function Targeting.NearestPlayerInBounds(self: Targeting, bounds: number, position: Vector3?): (Player?, number)
	local player, dist = self:NearestPlayer(position or self.primary.Position)

	if dist <= bounds then
		return player, dist
	else
		return nil, math.huge
	end
end

--[[
	Cleans up the object.

	@param self Targeting - the object
]]
function Targeting.Cleanup(self: Targeting)
	self._cleaner:Destroy()
end

return Targeting

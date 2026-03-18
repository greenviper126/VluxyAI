--!strict

------------------------------------------------------------------------------------------------------------------------

local Targeting = require(script.Parent.Parent.BaseAgents.Targeting)

------------------------------------------------------------------------------------------------------------------------

--[[
	Combat class for agents, responsible for handling combat-related actions and interactions with players.
	Inherits from Targeting to utilize common functionality related to targeting and player interactions.
]]
local Combat = {}
Combat.__index = Combat
setmetatable(Combat, Targeting)

type self = {}

export type Combat = typeof(setmetatable({} :: self, Combat)) & Targeting.Targeting

--[[
	Constructor for Combat class

	@param entity Model - the entity

	@return Combat - An instance of the Combat class initialized with the given entity.
]]
function Combat.new(entity: Model): Combat
	local self = setmetatable(Targeting.new(entity) :: Combat, Combat)

	return self
end

--[[
	Finds the nearest player to a given position and applies damage if they are within a certain distance.

	@param self Combat - the object
	@param position Vector3 - the position to check from
	@param distance number - the maximum distance to consider for damaging players
	@param damage number - the amount of damage to apply to players within distance
]]
function Combat.DamagePlayerInBounds(self: Combat, position: Vector3, distance: number, damage: number)
	local player, dist = self:NearestPlayer(position)

	if player and dist < distance then
		self:DamagePlayer(player, damage)
	end
end

--[[
	Applies damage to a player.

	@param self Combat - the object
	@param player Player - the player to damage
	@param damage number - the amount of damage to apply to the player
]]
function Combat.DamagePlayer(self: Combat, player: Player, damage: number)
	if not player.Character then
		return
	end

	local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then
		return
	end

	humanoid:TakeDamage(damage)
end

return Combat

--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------

local Trove = require(ReplicatedStorage.Packages.trove)

local vluxyAI = script.Parent.Parent

local TargetingBaseAgent = require(vluxyAI.BaseAgents.TargetingBaseAgent)

------------------------------------------------------------------------------------------------------------------------

--[[
	Combat class for agents, responsible for handling combat-related actions and interactions with players.
	Inherits from Targeting to utilize common functionality related to targeting and player interactions.
]]
local Combat = {}
Combat.__index = Combat

type self = {
	entity: Model,

	_targetingBaseAgent: TargetingBaseAgent.Targeting,

	_cleaner: typeof(Trove.new()),
}

export type Combat = typeof(setmetatable({} :: self, Combat))

--[[
	Constructor for Combat class

	@param entity Model - the entity

	@return Combat - An instance of the Combat class initialized with the given entity.
]]
function Combat.new(entity: Model, targetingBaseAgent: TargetingBaseAgent.Targeting): Combat
	local self = setmetatable({} :: self, Combat)
	self._cleaner = Trove.new()

	self.entity = entity

	self._targetingBaseAgent = targetingBaseAgent

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
	local player, dist = self._targetingBaseAgent:NearestPlayer(position)

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

--[[
	Cleans up the object.

	@param self Combat - the object
]]
function Combat.Cleanup(self: Combat)
	self._cleaner:Destroy()
end

return Combat

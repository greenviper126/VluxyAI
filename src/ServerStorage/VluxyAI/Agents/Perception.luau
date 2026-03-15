--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

local Perception = {}
Perception.__index = Perception

type self = {
	_cleaner: typeof(Trove.new()),
}

export type Perception = typeof(setmetatable({} :: self, Perception))

function Perception.new(entity: Model, PerceptionInfo: any): Perception
	local self = setmetatable({} :: self, Perception)
	self._cleaner = Trove.new()

	return self
end

--[[
is it possible for agent to see this position?
]]
function Perception.Obstructed(self: Perception, position: Vector3): RaycastResult?
	local params = self:AvoidParams("Both")
	local direction = (position - self._characterInfo.Primary.Position) -- keep magnitude
	return workspace:Raycast(self._characterInfo.Primary.Position, direction, params)
end

--[[
angle relation of a cordinate and position/dot product
]]
function Perception.PosInSightOfCord(self: Perception, cord: CFrame, pos2: Vector3, range: number?): (boolean, number)
	local range = range or self._info.VisualRange
	local direction = (pos2 - cord.Position).Unit
	local product = direction:Dot(cord.LookVector)
	return product > range, product
end

--[[
is target in line of sight with no obstructions?
]]
function Perception.AgentSeesTarget(self: Perception): boolean
	if not self.target then
		return false
	end
	local result = self:Obstructed(self.target.Primary.Position)
	local inSight, product = self:PosInSightOfCord(self._characterInfo.Primary.CFrame, self.target.Primary.Position)

	if not result and inSight then
		return true
	else
		return false
	end
end

--[[
is position in line of sight with no obstructions?
]]
function Perception.AgentSeesPosition(self: Perception, position: Vector3): boolean
	local result = self:Obstructed(position)
	local inSight, product = self:PosInSightOfCord(self._characterInfo.Primary.CFrame, position)

	if not result and inSight then
		return true
	else
		return false
	end
end

--[[
is agent in line of sight with no obstructions?
]]
function Perception.TargetSeesAgent(self: Perception): boolean
	if not self.target then
		return false
	end
	local result = self:Obstructed(self.target.Primary.Position)
	local inSight, product = self:PosInSightOfCord(self.target.Primary.CFrame, self._characterInfo.Primary.Position)

	if not result and inSight then
		return true
	else
		return false
	end
end

--[[
similar to AgentSeesTarget but accounts for all players
]]
function Perception.PlayersSeeAgent(self: Perception): { BasePart? }
	local roots = {}

	for _, root in pairs(PlayerFunctions.GetRoots() :: { BasePart }) do
		local inSight, product = self:PosInSightOfCord(root.CFrame, self._characterInfo.Primary.Position)
		local result = self:Obstructed(root.Position)

		if not result and inSight then
			table.insert(roots, root)
		end
	end

	return roots
end

function Perception.Cleanup(self: Perception)
	self._cleaner:Destroy()
end

return Perception

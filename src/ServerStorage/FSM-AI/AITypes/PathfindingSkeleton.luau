--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.trove)

local Pathfinding = {}
Pathfinding.__index = Pathfinding

export type PathfindingInfo = {
	AgentRadius: number?,
	AgentHeight: number?,
	AgentCanJump: boolean?,
	AgentCanClimb: boolean?,
	WaypointSpacing: number?,
	Costs: {
		[string]: number?,
	}?,

	NodeMap: {
		[number]: {
			Position: Vector3,
			Connections: { [number]: number }?,
		},
	}?,
}

type self = {
	type: "RobloxNavigationMesh",

	_pathfindingInfo: PathfindingInfo,
	_characterInfo: { [string]: any },

	_path: Path,
	_pathing: boolean,
	_goalPart: BasePart,
	_showPath: boolean,
	_errorCount: number,

	_visualParts: typeof(Trove.new()),

	_runConnection: RBXScriptConnection?,
	_moveConnection: RBXScriptConnection?,

	_cleaner: typeof(Trove.new()),
}

export type Pathfinding = typeof(setmetatable({} :: self, Pathfinding))

--constructor
function Pathfinding.new(characterInfo: any, pathfindingInfo: PathfindingInfo?): Pathfinding
	local self = setmetatable({} :: self, Pathfinding)

	return self
end

-- sets up the pathing
function Pathfinding._setPathInfo(self: Pathfinding, pathfindingInfo: PathfindingInfo)
	--
end

--ball part with multiple purposes
function Pathfinding._newPart(self: Pathfinding, name: string): BasePart
	return Instance.new("Part")
end

-- will attempt to reach goal through pathfinding if running
function Pathfinding.MoveTo(self: Pathfinding, destination: Vector3)
	--
end

-- visual show destination for debugging
function Pathfinding.ShowPath(self: Pathfinding, show: boolean)
	--
end

-- teleports the agent to given position
function Pathfinding.PivotAgent(self: Pathfinding, cordinate: CFrame)
	--
end

-- will run or stop pathfinding depending on input
-- used to stop the run and stop methods from being called multiple times
function Pathfinding.Toggle(self: Pathfinding, on: boolean)
	assert(typeof(on) == "boolean", typeof(on) .. " is not boolean.")

	if on == self._pathing then
		return
	end

	if on then
		self:Run()
	else
		self:Stop()
	end
end

-- follows current path
function Pathfinding.Run(self: Pathfinding)
	--
end

--stop following current path
function Pathfinding.Stop(self: Pathfinding)
	--
end

--compute path to goal
function Pathfinding._computeAsync(self: Pathfinding): Path?
	return nil
end

--visualize path
function Pathfinding._displayPath(self: Pathfinding, path: Path)
	--
end

--moves humanoid to goal
function Pathfinding._attemptPath(self: Pathfinding, goalPos: Vector3)
	--
end

-- the linear distance to current goal
function Pathfinding.GoalMagnitude(self: Pathfinding): number
	return 0
end

-- the distance of the current path
function Pathfinding.GoalDist(self: Pathfinding): number
	return 0
end

--cleanup everything
function Pathfinding.Destroy(self: Pathfinding)
	--
end

return Pathfinding

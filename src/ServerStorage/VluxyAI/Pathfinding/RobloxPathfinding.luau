--!strict

local DEFAULT_AGENT_SETTINGS: SetAgentSettings = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 2,
	Costs = {},
}

local DEFAULT_PATHFINDING_SETTINGS: SetPathfindingSettings = {
	MaxErrorCount = 20,
	PathingUpdateSpeed = 0.5,
	EntitySpeed = 8,
	VisualizePath = false,
	PredictTargetPosition = true,
	ShaveDownWaypoints = true,
}

------------------------------------------------------------------------------------------------------------------------

type BaseAgentSettings<N, B> = {
	AgentRadius: N,
	AgentHeight: N,
	AgentCanJump: B,
	AgentCanClimb: B,
	WaypointSpacing: N,
	Costs: {
		[string]: N,
	}?,
}

type BasePathfindingSettings<N, B> = {
	MaxErrorCount: N,
	PathingUpdateSpeed: N,
	EntitySpeed: N,
	VisualizePath: B,
	PredictTargetPosition: B,
	ShaveDownWaypoints: B,
}

export type AgentSettings = BaseAgentSettings<number?, boolean?>
type SetAgentSettings = BaseAgentSettings<number, boolean>

export type PathfindingSettings = BasePathfindingSettings<number?, boolean?>
type SetPathfindingSettings = BasePathfindingSettings<number, boolean>

------------------------------------------------------------------------------------------------------------------------

table.freeze(DEFAULT_AGENT_SETTINGS)
table.freeze(DEFAULT_PATHFINDING_SETTINGS)

------------------------------------------------------------------------------------------------------------------------

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.trove)

--used to make workspace not cluttered
local partsFolder = Instance.new("Folder")
partsFolder.Name = "PathfindingParts"
partsFolder.Parent = workspace

------------------------------------------------------------------------------------------------------------------------

--[[
	RobloxPathfinding Class, which uses Roblox's built in PathfindingService to move an agent to a target position while avoiding obstacles. It also has some extra features like error handling and path visualization.
]]
local Pathfinding = {}
Pathfinding.__index = Pathfinding
Pathfinding.PartsFolder = partsFolder

type Trove = typeof(Trove.new())

type self = {
	entity: Model,
	primary: BasePart,
	humanoid: Humanoid,

	agentSettings: SetAgentSettings,
	pathfindingSettings: SetPathfindingSettings,

	_path: Path,
	_targetPart: BasePart,
	_errorCount: number,
	_pathing: boolean,

	_targetVelocity: Vector3,

	_visualParts: Trove?,
	_moveCleaner: Trove?,
	_runningCleaner: Trove?,
	_cleaner: Trove,
}

export type Pathfinding = typeof(setmetatable({} :: self, Pathfinding))

--[[
	Creates a new Pathfinding object for the given entity. The entity must have a PrimaryPart and a Humanoid.

	@param entity Model - the Model that the Pathfinding will control

	@return Pathfinding - the object
]]
function Pathfinding.new(entity: Model): Pathfinding
	local primary = entity.PrimaryPart
	local humanoid = entity:FindFirstChildOfClass("Humanoid")

	assert(primary, "Entity must have a PrimaryPart! " .. entity:GetFullName())
	assert(humanoid, "Entity must have a Humanoid! " .. entity:GetFullName())

	local self = setmetatable({} :: self, Pathfinding)
	self._cleaner = Trove.new()

	self.entity = entity
	self.primary = primary
	self.humanoid = humanoid

	self.agentSettings = table.clone(DEFAULT_AGENT_SETTINGS)
	self.pathfindingSettings = table.clone(DEFAULT_PATHFINDING_SETTINGS)

	self._targetPart = self._cleaner:Add(self._newBall("Target"))
	self._errorCount = 0
	self._pathing = false
	self._targetVelocity = Vector3.zero

	return self
end

--[[
	Multiuse part used in path visualization and other stuff.

	@param name string - the name of the part to create

	@return BasePart - the created part
]]
function Pathfinding._newBall(name: string): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.one
	part.CanTouch = false
	part.CanCollide = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Ball
	part.Locked = true
	part.CastShadow = false
	part.Transparency = 1
	part.Anchored = true
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(0, 1, 0)
	part.Parent = Pathfinding.PartsFolder

	return part
end

--[[
	Same as what PathfindingService uses for settings for the pathing mesh. Resets settings if no settings are provided.

	@param self Pathfinding - the object
	@param agentSettings AgentSettings? - a table containing the pathfinding info to set

	@return Pathfinding - the object
]]
function Pathfinding.SetAgentSettings(self: Pathfinding, agentSettings: AgentSettings?): Pathfinding
	if not agentSettings then
		self.agentSettings = table.clone(DEFAULT_AGENT_SETTINGS)
		return self
	end

	for k: string, v in pairs(agentSettings) do
		if DEFAULT_AGENT_SETTINGS[k] == nil then
			warn("Invalid agent setting named " .. k .. "!", self.entity:GetFullName())
			continue
		end

		self.agentSettings[k] = v
	end

	return self
end

--[[
	Special Settings specific to this class. Resets settings if no settings are provided.

	@param self Pathfinding - the object
	@param pathfindingSettings PathfindingSettings? - a table containing the pathfinding settings to set

	@return Pathfinding - the object
]]
function Pathfinding.SetPathSettings(self: Pathfinding, pathfindingSettings: PathfindingSettings?): Pathfinding
	if not pathfindingSettings then
		self.pathfindingSettings = table.clone(DEFAULT_PATHFINDING_SETTINGS)
		return self
	end

	for k: string, v in pairs(pathfindingSettings) do
		if DEFAULT_PATHFINDING_SETTINGS[k] == nil then
			warn("Invalid pathfinding setting called " .. k .. "!", self.entity:GetFullName())
			continue
		end

		self.pathfindingSettings[k] = v
	end

	return self
end

--[[
	Returns whether the agent is currently pathing to the target.

	@param self Pathfinding - the object

	@return boolean - whether the agent is currently pathing
]]
function Pathfinding.IsPathing(self: Pathfinding): boolean
	return self._pathing
end

--[[
	Builds the pathing area for the agent.

	@param self Pathfinding - the object

	@return Pathfinding - the object
]]
function Pathfinding._buildPathingArea(self: Pathfinding)
	self._path = PathfindingService:CreatePath(self.agentSettings)
end

--[[
	Computes the path from the agent to the target. If the path is already computed and the target hasn't changed, it will return the existing path.

	@param self Pathfinding - the object

	@return Path? - the computed path, or nil if failed
]]
function Pathfinding._computePathing(self: Pathfinding): Path?
	if not self._path then
		self:_buildPathingArea()
	end

	local path: Path = self._path
	local success = pcall(function()
		local predictTargetPosition = self.pathfindingSettings.PredictTargetPosition
		local overshootAdditive = predictTargetPosition and self._targetVelocity / 2 or Vector3.zero

		path:ComputeAsync(self.primary.Position, self._targetPart.Position + overshootAdditive)
	end)

	if success then
		return path
	else
		warn("could not compute path! ", self.entity:GetFullName())

		return nil
	end
end

--[[
	Displays the computed path using parts. It will create a part for each waypoint and position it at the waypoint's position. It will also destroy any existing visual parts before creating new ones.

	@param self Pathfinding - the object
	@param waypoints { PathWaypoint } - the waypoints of the path to visualize

	@return Pathfinding - the object
]]
function Pathfinding._displayPath(self: Pathfinding, waypoints: { PathWaypoint })
	if self._visualParts then
		self._visualParts:Destroy()
	end
	if not self.pathfindingSettings.VisualizePath then
		return
	end

	local visualParts = self._cleaner:Extend()

	for i, waypoint in ipairs(waypoints) do
		local part = visualParts:Add(self._newBall("waypoint" .. i))
		part.Transparency = 0.5
		part.Position = waypoint.Position
		part.Size = Vector3.one * 0.5

		part.Color = Color3.new(i / #waypoints, 1, 0)

		if i == #waypoints then
			part.Color = Color3.new(1, 1, 1)
			part.Size = Vector3.one
		end
	end

	self._visualParts = visualParts
end

--[[
	Toggles the pathfinding on or off. If on is true, it will run the pathfinding loop. If on is false, it will stop the pathfinding loop.

	@param self Pathfinding - the object
	@param on boolean - whether to turn on or off the pathfinding

	@return Pathfinding - the object
]]
function Pathfinding.Toggle(self: Pathfinding, on: boolean): Pathfinding
	assert(typeof(on) == "boolean", typeof(on) .. " is not boolean!")

	if on and not self._runningCleaner then
		self:Run()
	elseif not on and self._runningCleaner then
		self:Stop()
	end

	return self
end

--[[
	Runs the pathfinding loop, which will continuously compute paths and move the agent along them until stopped.

	@param self Pathfinding - the object

	@return Pathfinding - the object
]]
function Pathfinding.Run(self: Pathfinding): Pathfinding
	self:Stop()

	local runCleaner = self._cleaner:Extend()
	runCleaner:Add(function()
		self._errorCount = 0
		self._pathing = false
	end)

	--adjust walk speed of entity
	self.humanoid.WalkSpeed = self.pathfindingSettings.EntitySpeed
	runCleaner:Connect(self.humanoid:GetPropertyChangedSignal("WalkSpeed"), function()
		self.humanoid.WalkSpeed = self.pathfindingSettings.EntitySpeed
	end)

	runCleaner:Add(function()
		self.humanoid:MoveTo(self.primary.Position)
	end)

	--after physics simulation
	local prevTargetPos = self._targetPart.Position
	runCleaner:Connect(RunService.Heartbeat, function(delta: number)
		self._targetVelocity = (self._targetPart.Position - prevTargetPos) / delta
		prevTargetPos = self._targetPart.Position
	end)

	--pathfinding loop
	local prevTime = 0
	runCleaner:Connect(RunService.Stepped, function(_delta: number)
		if time() - prevTime < self.pathfindingSettings.PathingUpdateSpeed then
			return
		end
		prevTime = time()

		self:_pathToTarget()
	end)

	self._runningCleaner = runCleaner

	return self
end

--[[
	Stops the pathfinding loop.

	@param self Pathfinding - the object

	@return Pathfinding - the object
]]
function Pathfinding.Stop(self: Pathfinding): Pathfinding
	if self._runningCleaner then
		self._runningCleaner:Clean()
	end
	self._runningCleaner = nil

	return self
end

--[[
	Moves the agent to the specified destination.

	@param self Pathfinding - the object
	@param destination Vector3 - the position to move to

	@return Pathfinding - the object
]]
function Pathfinding.MoveTo(self: Pathfinding, destination: Vector3): Pathfinding
	assert(typeof(destination) == "Vector3", typeof(destination) .. " is not a Vector3.")

	self._targetPart.Position = destination

	return self
end

--[[
	Moves the agent to the specified destination and yields until the path is complete or fails.

	@yields until the path is complete or fails

	@param self Pathfinding - the object
	@param destination Vector3 - the position to move to

	@return Pathfinding - the object
]]
function Pathfinding.MoveToYield(self: Pathfinding, destination: Vector3): Pathfinding
	self:MoveTo(destination)

	--this might yield infinitely on cleanup in some cases. But, it works for now.
	repeat
		task.wait()
	until not self._pathing

	return self
end

--[[
	Pivots the agent to the specified coordinate.

	@param self Pathfinding - the object
	@param coordinate CFrame - the CFrame to pivot to

	@return Pathfinding - the object
]]
function Pathfinding.PivotAgent(self: Pathfinding, coordinate: CFrame)
	assert(typeof(coordinate) == "CFrame", typeof(coordinate) .. " is not a CFrame.")

	self:Stop()
	self.primary:PivotTo(coordinate)
	self._targetPart.Position = coordinate.Position
end

--[[
	Internal function that removes unnecessary waypoints that are in a straight line to make the path smoother.

	@param waypoints { PathWaypoint } - the waypoints to shave down

	@return { PathWaypoint } - the shaved down waypoints
]]
function Pathfinding._shaveDownWaypoints(waypoints: { PathWaypoint }): { PathWaypoint }
	if #waypoints <= 2 then
		return waypoints
	end

	local shavedWaypoints = {}
	local unitDirections = {}

	local prevPosition = waypoints[1].Position
	for i = 2, #waypoints do
		local waypoint = waypoints[i]

		local direction = (waypoint.Position - prevPosition).Unit
		table.insert(unitDirections, direction)

		prevPosition = waypoint.Position
	end

	local prevValidDirection = unitDirections[1]
	for i = 2, #unitDirections - 1 do
		local direction = unitDirections[i]

		if direction:Dot(prevValidDirection) < 0.99 then
			table.insert(shavedWaypoints, waypoints[i])
			prevValidDirection = direction
		end
	end
	table.insert(shavedWaypoints, waypoints[#waypoints])

	return shavedWaypoints
end

--[[
	Internal function that moves the agent along the given waypoints.

	@param self Pathfinding - the object
	@param waypoints { PathWaypoint } - the waypoints to move along

	@return Pathfinding - the object
]]
function Pathfinding._pathFromWaypoints(self: Pathfinding, waypoints: { PathWaypoint })
	if #waypoints == 0 then
		return
	elseif #waypoints == 1 then
		self.humanoid:MoveTo(waypoints[1].Position)
		return
	end

	if not self._runningCleaner then
		return
	end
	if self._moveCleaner then
		self._moveCleaner:Destroy()
	end

	local moveCleaner = self._runningCleaner:Extend()
	local nextWaypointIndex = 1

	moveCleaner:Add(function()
		self._pathing = false
	end)

	self._pathing = true
	moveCleaner:Connect(self.humanoid.MoveToFinished, function(reached: boolean)
		if reached and nextWaypointIndex < #waypoints then
			nextWaypointIndex += 1

			self.humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
		else
			moveCleaner:Destroy()
		end
	end)

	self.humanoid:MoveTo(waypoints[nextWaypointIndex].Position)

	self._moveCleaner = moveCleaner
end

--[[
	Internal function that handles moving the agent along the computed path and handling path errors.

	@param self Pathfinding - the object

	@return Pathfinding - the object
]]
function Pathfinding._pathToTarget(self: Pathfinding)
	local path = self:_computePathing()
	if not path then
		return
	end

	local waypoints = path:GetWaypoints()
	if self.pathfindingSettings.ShaveDownWaypoints then
		waypoints = self._shaveDownWaypoints(waypoints)
	end

	self:_displayPath(waypoints)

	if path.Status == Enum.PathStatus.Success then
		self._errorCount = 0

		self:_pathFromWaypoints(waypoints)
	else
		self._errorCount += 1
	end

	if
		self._errorCount >= self.pathfindingSettings.MaxErrorCount
		and self._errorCount % self.pathfindingSettings.MaxErrorCount == 0
	then
		warn("Pathfinding is currently obstructed! ", self.entity:GetFullName())
	end
end

--[[
	Returns the magnitude from the agent to the target.

	@param self Pathfinding - the object

	@return number - the magnitude
]]
function Pathfinding.GoalMagnitude(self: Pathfinding): number
	return (self.primary.Position - self._targetPart.Position).Magnitude
end

--[[
	Returns the distance from the agent to the target along the path. If there is no path, it will return math.huge.

	@param self Pathfinding - the object

	@return number - the distance
]]
function Pathfinding.GoalDistance(self: Pathfinding): number
	if not self._path then
		return math.huge
	end

	local waypoints = self._path:GetWaypoints()
	if #waypoints < 2 then
		return math.huge
	end

	local distance = self.agentSettings.WaypointSpacing or 2
	return distance * #waypoints - distance
end

--[[
	Cleans up the object.

	@param self Pathfinding - the object
]]
function Pathfinding.Cleanup(self: Pathfinding)
	self._cleaner:Destroy()
end

return Pathfinding

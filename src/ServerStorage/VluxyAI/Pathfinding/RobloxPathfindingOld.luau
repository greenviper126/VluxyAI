--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.trove)

local SharedTypes = require(script.Parent.Parent.AITypes)

--[[
    Pathfinding class for Roblox Navigation Mesh. Uses Roblox's built in PathfindingService to compute paths and move the agent along them. Also has functionality for visualizing the path and handling path errors.
]]
local Pathfinding = {}
Pathfinding.__index = Pathfinding

Pathfinding.PathReadjustRate = 1 --seconds
Pathfinding.ErrorWarnRetry = 20 --errorCount

Pathfinding.PartsFolder = Instance.new("Folder")
Pathfinding.PartsFolder.Name = "RobloxNavigationMeshParts"
Pathfinding.PartsFolder.Parent = workspace

Pathfinding.PathfindingInfoDefault = {
	AgentRadius = 3,
	AgentHeight = 6,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 2,
	Costs = {
		Avoid = math.huge,
		Follow = 0.1,
		Door = 100,
	},
} :: SharedTypes.PathfindingInfo

type self = {
	type: "RobloxNavigationMesh",

	entity: Model,
	primary: BasePart,
	humanoid: Humanoid,

	_pathfindingInfo: SharedTypes.PathfindingInfo,
	--_characterInfo: SharedTypes.CharacterInfo,

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

--this should just need a model and path info

--[[
    constructor for Pathfinding class. Takes in characterInfo and pathfindingInfo and sets up the pathfinding instance.

    @param characterInfo - the character info for the agent that will be pathfinding
    @param pathfindingInfo - the pathfinding info for the pathfinding instance. If nil, default info will be used.

    @return Pathfinding - the created pathfinding instance
]]
function Pathfinding.new(entity: Model, pathfindingInfo: SharedTypes.PathfindingInfo?): Pathfinding
	assert(typeof(entity) == "Instance" and entity:IsA("Model"), typeof(entity) .. " is not a Model.")
	assert(
		typeof(pathfindingInfo) == "table" or pathfindingInfo == nil,
		typeof(Pathfinding) .. " is not a pathfindingInfo table or nil."
	)

	local self = setmetatable({} :: self, Pathfinding)
	self._cleaner = Trove.new()

	self.entity = entity
	self.primary = entity.PrimaryPart :: BasePart
	self.humanoid = entity:FindFirstChildOfClass("Humanoid") :: Humanoid

	self._pathfindingInfo = (
		pathfindingInfo and setmetatable(pathfindingInfo, Pathfinding.PathfindingInfoDefault)
		or Pathfinding.PathfindingInfoDefault
	) :: SharedTypes.PathfindingInfo

	self._goalPart = self:_newPart("Goal")
	self._pathing = false
	self._showPath = false
	self._errorCount = 0

	self:_setPathInfo(self._pathfindingInfo)

	return self
end

--[[
    creates a new part with the given name and default properties for visualizing the path. The part is parented to Pathfinding.PartsFolder.

    @param self - the object
    @param name - the name of the part

    @return BasePart - the created part
]]
function Pathfinding._newPart(self: Pathfinding, name: string): BasePart
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
    Sets the pathfinding info for the pathfinding instance and creates a new path with the new info.

    @param self - the object
    @param pathfindingInfo - the new pathfinding info to set
]]
function Pathfinding._setPathInfo(self: Pathfinding, pathfindingInfo: SharedTypes.PathfindingInfo)
	self._path = PathfindingService:CreatePath(pathfindingInfo :: { [string]: any })
end

--[[
    Compute path to goal asynchronously and return the path. Will return nil if path could not be computed.

    @param self - the object

    @return Path? - the computed path or nil if path could not be computed
]]
function Pathfinding._computeAsync(self: Pathfinding): Path?
	if not self._path then
		self:_setPathInfo(self._pathfindingInfo)
	end

	local newPath: Path = self._path

	local success = pcall(function()
		newPath:ComputeAsync(self.primary.Position, self._goalPart.Position)
	end)

	if success then
		return newPath
	else
		warn("could not compute path, ", self.entity:GetFullName())
		return nil
	end
end

-- --[[
--     Toggles pathfinding on or off.

--     @param self - the object
--     @param on - whether to toggle pathfinding on or off
-- ]]
-- function Pathfinding.Toggle(self: Pathfinding, on: boolean)
-- 	assert(typeof(on) == "boolean", typeof(on) .. " is not boolean.")

-- 	if on == self._pathing then
-- 		return
-- 	end

-- 	if on then
-- 		self:Run()
-- 	else
-- 		self:Stop()
-- 	end
-- end

--[[
    Follows current path.

    @param self - the object
]]
function Pathfinding.Run(self: Pathfinding)
	self:Stop()
	self._pathing = true

	self:_setPathInfo(self._pathfindingInfo)

	local prevTime = 0
	self._runConnection = RunService.Heartbeat:Connect(function()
		if time() - prevTime < Pathfinding.PathReadjustRate then
			return
		end
		prevTime = time()

		self:_attemptPath(self._goalPart.Position)
	end)
end

--[[
    Stop following current path and disconnects all connections related to pathfinding. Also destroys visual parts if they exist.

    @param self - the object
]]
function Pathfinding.Stop(self: Pathfinding)
	self._pathing = false
	self._errorCount = 0

	self._goalPart.Position = self.primary.Position
	self.humanoid:MoveTo(self.primary.Position)

	if self._runConnection then
		self._runConnection:Disconnect()
	end

	if self._moveConnection then
		self._moveConnection:Disconnect()
	end

	if self._visualParts then
		self._visualParts:Destroy()
	end
end

-- --[[
--     Visualize the destination for debugging purposes.

--     @param self - the object
--     @param show - whether to show the path or not
-- ]]
-- function Pathfinding.ShowPath(self: Pathfinding, show: boolean)
-- 	assert(typeof(show) == "boolean", typeof(show) .. " is not boolean.")

-- 	self._showPath = show
-- end

-- --[[
--     Displays the computed path using visual parts.

--     @param self - the object
--     @param path - the path to display
-- ]]
-- function Pathfinding._displayPath(self: Pathfinding, path: Path)
-- 	if self._visualParts then
-- 		self._visualParts:Destroy()
-- 	end
-- 	self._visualParts = self._cleaner:Extend()

-- 	task.delay(Pathfinding.PathReadjustRate + 5, function()
-- 		if self._visualParts then
-- 			self._visualParts:Destroy()
-- 		end
-- 	end)

-- 	local waypoints = path:GetWaypoints()
-- 	for i, waypoint in pairs(waypoints) do
-- 		local part = self._visualParts:Add(self:_newPart("waypoint"))
-- 		part.Transparency = 0.5
-- 		part.Position = waypoint.Position
-- 		part.Size = Vector3.one * 0.5

-- 		if i == #waypoints then
-- 			part.Color = Color3.new(1, 1, 1)
-- 			part.Size = Vector3.one
-- 		end
-- 	end
-- end

--[[
    Moves humanoid to goal.

    @param self - the object
    @param destination - the position to move to
]]
function Pathfinding.MoveTo(self: Pathfinding, destination: Vector3)
	assert(typeof(destination) == "Vector3", typeof(destination) .. " is not a Vector3.")
	self._goalPart.Position = destination
end

-- --[[
--     Pivots the agent to the given coordinate and updates the goal position to match. Will also stop any current pathing.

--     @param self - the object
--     @param coordinate - the coordinate to pivot the agent to
-- ]]
-- function Pathfinding.PivotAgent(self: Pathfinding, coordinate: CFrame)
-- 	assert(typeof(coordinate) == "CFrame", typeof(coordinate) .. " is not a CFrame.")

-- 	self:Stop()
-- 	self.primary:PivotTo(coordinate)
-- 	self._goalPart.Position = coordinate.Position
-- end

--[[
    Will attempt to path to goal and move the agent along the path. Will also handle path errors and display the path if showPath is true.

    @param self - the object
    @param goalPos - the position to path to
]]
function Pathfinding._attemptPath(self: Pathfinding, goalPos: Vector3)
	local path = self:_computeAsync()
	if not path then
		return
	end

	--self:_displayPath(path)

	local function goTo(waypoints: { PathWaypoint })
		if self._moveConnection then
			self._moveConnection:Disconnect()
		end

		if #waypoints < 2 then
			return
		end
		local nextWaypointIndex = 2

		self._moveConnection = self.humanoid.MoveToFinished:Connect(function(reached: boolean)
			if reached and nextWaypointIndex < #waypoints then
				nextWaypointIndex += 1

				self.humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
			else
				if self._moveConnection then
					self._moveConnection:Disconnect()
				end
			end
		end)

		self.humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
	end

	local waypoints = path:GetWaypoints()
	if path.Status == Enum.PathStatus.Success then
		self._errorCount = 0
		goTo(waypoints)
	else
		self._errorCount += 1
	end

	if self._errorCount >= Pathfinding.ErrorWarnRetry and self._errorCount % Pathfinding.ErrorWarnRetry == 0 then
		warn("Pathfinding is currently obstructed, ", self.entity:GetFullName())
	end
end

-- --[[
--     The linear distance to current goal.

--     @param self - the object

--     @return number - the linear distance to current goal
-- ]]
-- function Pathfinding.GoalMagnitude(self: Pathfinding): number
-- 	return (self.primary.Position - self._goalPart.Position).Magnitude
-- end

-- --[[
--     The distance of the current path. Will return math.huge if no path or a path with less than 2 waypoints exists.

--     @param self - the object

--     @return number - the distance of the current path
-- ]]
-- function Pathfinding.GoalDistance(self: Pathfinding): number
-- 	if not self._path then
-- 		return math.huge
-- 	end

-- 	local waypoints = self._path:GetWaypoints()
-- 	if #waypoints < 2 then
-- 		return math.huge
-- 	end

-- 	local distance = self._pathfindingInfo.WaypointSpacing or 2
-- 	return (distance * #waypoints) - distance
-- end

--[[
    Destroys the pathfinding object.

    @param self - the object
]]
function Pathfinding.Destroy(self: Pathfinding)
	self._cleaner:Destroy()
end

return Pathfinding

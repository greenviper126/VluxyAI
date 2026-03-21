--!strict

--[[
	Note:
	
	the types can be simplified after testing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.trove)

type State = {
	Start: (self: any) -> (),
	Update: (self: any) -> string?,
	End: (self: any) -> (),
}

type StateData = {
	states: { [string]: State },
	fallbackState: string,

	_cleaner: typeof(Trove.new()),
}

type self = {
	entity: Model,

	_stateData: StateData,

	_validated: boolean,
	_started: boolean,

	_cleaner: typeof(Trove.new()),
}

--[[
    Builder Class for State Pattern State Machines (SPSM).
]]
local Builder = {}
Builder.__index = Builder

export type Builder = typeof(setmetatable({} :: self, Builder))

--[[
    Builds a New SPSM Entity.
]]
function Builder.new(entity: Model): Builder
	local self = setmetatable({} :: self, Builder)
	self._cleaner = Trove.new()

	self.entity = entity

	self._validated = false
	self._started = false

	return self
end

--[[
    Checks if the FSM-AI has already been started. If it has, it will warn the user and return true.

    @param self - the object

    @return boolean - whether the FSM-AI has already been started or not
]]
function Builder._startCheck(self: Builder)
	if self._started then
		warn("FSM-AI has already been started for this entity! : " .. self.entity:GetFullName())
	end

	return self._started
end

--[[
    Sets the state data for the FSM-AI.

    @param self - the object
    @param stateData - the state data object

    @return self - the object
]]
function Builder.SetStateData(self: Builder, stateData: StateData & { any }): Builder
	if self:_startCheck() then
		return self
	end

	self._stateData = stateData
	self._cleaner:Add(stateData._cleaner)

	return self
end

--[[
    Checks if the build is valid and Builds the states for the FSM-AI. Can be ran multiple times.

    @param self - the object

    @return self - the object
]]
function Builder.Build(self: Builder): Builder
	if self:_startCheck() then
		return self
	end

	if not self._stateData.fallbackState then
		error("No fallback state set for FSM-AI! " .. self.entity:GetFullName())
	end

	--validate state data
	for stateName, state in self._stateData.states do
		if type(state.Start) ~= "function" then
			error("State " .. stateName .. " is missing a Start function!")
		end

		if type(state.Update) ~= "function" then
			error("State " .. stateName .. " is missing an Update function!")
		end

		if type(state.End) ~= "function" then
			error("State " .. stateName .. " is missing an End function!")
		end
	end

	self._validated = true

	return self
end

--[[
    Starts the FSM-AI. Can only be ran once.

    @param self - the object

    @return self - the object
]]
function Builder.Start(self: Builder): Builder
	if not self._stateData then
		warn("AI was not built! " .. self.entity:GetFullName())
		return self
	end
	if not self._validated then
		warn("FSM-AI has not been validated for this entity! : " .. self.entity:GetFullName())
		return self
	end
	if self:_startCheck() then
		return self
	end

	self._started = true

	self._cleaner:Add(task.spawn(function()
		local nextState = self:_getStateFromName(self._stateData.fallbackState)

		while true do
			nextState = self:_getStateFromName(self:_runState(nextState))
		end
	end))

	return self
end

--[[
	Runs the state and returns the next state name. If the next state name is nil, it will return the fallback state.

	@param self - the object
	@param state - the state to run

	@return string - the name of the next state
]]
function Builder._runState(self: Builder, state: State): string
	local nextStateName: string = nil
	local cleaner = self._cleaner:Extend()
	local stateChanged = cleaner:Add(Instance.new("BindableEvent"))

	state.Start(self._stateData)

	local prevTime = os.clock()
	cleaner:Connect(RunService.Heartbeat, function()
		if os.clock() - prevTime < 0.1 then
			return
		end
		prevTime = os.clock()

		local newStateName = state.Update(self._stateData)

		if newStateName then
			nextStateName = newStateName
			stateChanged:Fire()
		end
	end)

	stateChanged.Event:Wait()
	cleaner:Destroy()

	state.End(self._stateData)

	return nextStateName
end

--[[
	Gets the state from the state name. If the state name is nil or invalid, it will return the fallback state.

	@param self - the object
	@param stateName - the name of the state

	@return State - the state object
]]
function Builder._getStateFromName(self: Builder, stateName: string?): State
	if stateName == nil then
		warn("No state was provided, going to fallback state! " .. self.entity:GetFullName())

		return self._stateData.states[self._stateData.fallbackState]
	elseif not self._stateData.states[stateName] then
		warn("State name is not valid, going to fallback state! " .. self.entity:GetFullName())

		return self._stateData.states[self._stateData.fallbackState]
	else
		return self._stateData.states[stateName]
	end
end

--[[
    Destroys the FSM-AI and cleans up all connections. Can only be ran once.

    @param self - the object
]]
function Builder.Destroy(self: Builder)
	self._cleaner:Destroy()
end

return Builder

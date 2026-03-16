--!strict

--[[
	Note:
	Internally this module is a mess atm.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

local StateTypes = require(script.Parent.AITypes)

local RobloxPathfinding = require(script.Parent.Pathfinding.RobloxPathfinding)

type self = {
	entity: Model,

	rawStates: { [string]: StateTypes.RawState },
	fallbackState: string,

	_states: { [string]: StateTypes.State },
	_started: boolean,

	_cleaner: typeof(Trove.new()),
}

--[[
    Builder Class for FSM-AI.
]]
local Builder = {}
Builder.__index = Builder

export type Builder = typeof(setmetatable({} :: self, Builder))

--[[
    Builds a New FSM-AI Entity.
]]
function Builder.new(entity: Model): Builder
	local self = setmetatable({} :: self, Builder)
	self._cleaner = Trove.new()

	self.entity = entity
	self.fallbackState = "None"

	self.rawStates = {}
	self._states = {}

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
    Sets the fallback state for the FSM-AI. The fallback state is the state that the FSM-AI will default to if it cannot find a valid state to transition to.

    @param self - the object
    @param fallbackState - the name of the fallback state

    @return self - the object
]]
function Builder.SetFallbackState(self: Builder, fallbackState: string): Builder
	if self:_startCheck() then
		return self
	end

	self.fallbackState = fallbackState

	return self
end

--[[
    Sets a state for the FSM-AI.

    @param self - the object
    @param name - the name of the state
    @param state - the state object

    @return self - the object
]]
function Builder.SetState(self: Builder, name: string, state: StateTypes.RawState): Builder
	if self:_startCheck() then
		return self
	end

	self.rawStates[name] = state

	return self
end

--[[
    Removes a state for the FSM-AI.

    @param self - the object
    @param name - the name of the state

    @return self - the object
]]
function Builder.RemoveState(self: Builder, name: string): Builder
	if self:_startCheck() then
		return self
	end

	self.rawStates[name] = nil

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

	--build state table from rawStates somewhere in here!

	-- entity
	if not self.entity.PrimaryPart then
		warn("FSM-AI is missing an entity with a Primary Part! : " .. self.entity:GetFullName())
	end

	local agent = {}
	local navigator = RobloxPathfinding.new({}, {})

	-- states
	for name, state in self.rawStates do
		if type(state) ~= "table" then
			warn("FSM-AI has a state that is not a table! State Name: " .. name .. " : " .. self.entity:GetFullName())
		end

		for transitionName, transitionFunc in state.Transitions do
			if type(transitionFunc) ~= "function" then
				warn(
					"FSM-AI has a transition that is not a function! State Name: "
						.. name
						.. " Transition Name: "
						.. transitionName
						.. " : "
						.. self.entity:GetFullName()
				)
			end

			if not self.rawStates[transitionName] then
				warn(
					"FSM-AI has a transition to a state that does not exist! State Name: "
						.. name
						.. " Transition Name: "
						.. transitionName
						.. " : "
						.. self.entity:GetFullName()
				)
			end
		end

		self._states[name] = {
			Transitions = table.clone(state.Transitions),

			Start = state.Start,
			Update = state.Update,
			End = state.End,

			Agent = agent,
			Navigator = navigator,

			Data = {},
		}
	end

	-- fallbackState
	if not self.fallbackState then
		warn("FSM-AI is missing a fallback state! : " .. self.entity:GetFullName())
	end

	return self
end

--[[
    Starts the FSM-AI. Can only be ran once.

    @param self - the object

    @return self - the object
]]
function Builder.Start(self: Builder): Builder
	if not self._states then
		warn("AI was not built! " .. self.entity:GetFullName())
		return self
	end

	if self:_startCheck() then
		return self
	end

	self._started = true

	print("Started")

	--logic to start the FSM-AI goes here!

	return self
end

--[[
    Destroys the FSM-AI and cleans up all connections. Can only be ran once.

    @param self - the object
]]
function Builder.Destroy(self: Builder)
	self._cleaner:Destroy()
end

return Builder

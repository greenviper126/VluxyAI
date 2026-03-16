--!strict

--[[
	Note:
	For transitions to make more sense and to add in Utility I may just have to instead return a number on transition.

	Also, update has a delta variable but if its not per frame maybe thats not useful?

	Overall need to confirm if this method is valid for the requirements i need.
]]

local StateTypes = require(script.Parent.Parent.AITypes)

local Idle: StateTypes.RawState = {
	Transitions = {
		Walk = function(self)
			return true
		end,
		Chase = function(self)
			return true
		end,
	},

	Start = function(self)
		print("Starting Idle State")
	end,

	Update = function(self, delta)
		print("Updating Idle State")
	end,

	End = function(self)
		print("Ending Idle State")
	end,
}

return Idle

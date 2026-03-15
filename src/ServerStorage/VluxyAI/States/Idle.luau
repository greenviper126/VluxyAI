--!strict

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

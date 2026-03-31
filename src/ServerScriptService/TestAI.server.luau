--!strict

local ServerStorage = game:GetService("ServerStorage")

------------------------------------------------------------------------------------------------------------------------

local VluxyAI = ServerStorage.VluxyAI

local BasicKillerStates = require(VluxyAI.BasicStates.Killer)

local Builder = require(VluxyAI.AIBuilder)

------------------------------------------------------------------------------------------------------------------------

local entity = workspace:FindFirstChild("Rig") :: Model

------------------------------------------------------------------------------------------------------------------------

local ai = Builder.new(entity)

ai:SetStandardStateData(BasicKillerStates)

ai:Build():Start()

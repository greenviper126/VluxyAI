--!strict

local ServerStorage = game:GetService("ServerStorage")

------------------------------------------------------------------------------------------------------------------------

local VluxyAI = ServerStorage.VluxyAI

local BasicKillerStates = require(VluxyAI.States.BasicKiller)

local Builder = require(VluxyAI.Builders.SPSMBuilder)

------------------------------------------------------------------------------------------------------------------------

local entity = workspace:FindFirstChild("Rig") :: Model

------------------------------------------------------------------------------------------------------------------------

local ai = Builder.new(entity)

ai:SetStandardStateData(BasicKillerStates)

ai:Build():Start()

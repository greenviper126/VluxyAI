--!strict

--[[
	Note:
	This file may change or be completely removed in the future.
]]

export type PathfindingInfo = {
	AgentRadius: number?,
	AgentHeight: number?,
	AgentCanJump: boolean?,
	AgentCanClimb: boolean?,
	WaypointSpacing: number?,
	Costs: {
		[string]: number?,
	}?,
}

export type EnemyTypes = "Default" | "Test"
export type PathTypes = "RobloxNavigationMesh" | "AStar"

export type CharacterInfo = {
	EnemyType: EnemyTypes,
	PathingType: PathTypes,
	Model: Model,
	Primary: BasePart,
	Humanoid: Humanoid,
	Animator: Animator,
}

export type PlayerInfo = {
	Player: Player,
	Model: Model,
	Primary: BasePart,
	Humanoid: Humanoid,
	Animator: Animator,
}

export type AgentInfo<N, S> = {
	Speed: N,
	DetectDist: N,
	CollisionRays: N,
	CollisionDist: N,
	SpreadDist: N,
	VisualRange: N,
	AgentCollision: S,
}

export type State = {
	Start: (self: State) -> (),
	Update: (self: State) -> string?,
	End: (self: State) -> (),
}

export type BlankStateObject = {
	Agent: any,
	Pathfinder: any,
	States: { [string]: State },
	Data: { [string]: any },
}

return nil

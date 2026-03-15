--!strict

local PathfindingSkeleton = require(script.PathfindingSkeleton)

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

export type Agent = { any }

export type Navigator = { any } --PathfindingSkeleton.Pathfinding

export type RawState = {
	Transitions: { [string]: (self: State) -> boolean },

	Start: (self: State) -> (),
	Update: (self: State, delta: number) -> (),
	End: (self: State) -> (),
}

export type State = RawState & {
	Agent: Agent,
	Navigator: Navigator,

	Data: { [string]: any },
}

return nil

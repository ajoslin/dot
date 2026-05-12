export type GoalStatus = "active" | "paused" | "budget_limited" | "complete";
export type GoalPausedReason = "user" | "interrupted" | "budget_limited";

export type GoalEntry = {
	goalId: string;
	threadId: string;
	objective: string;
	status: GoalStatus;
	tokenBudget: number | null;
	tokensUsed: number;
	timeUsedSeconds: number;
	createdAt: number;
	updatedAt: number;
	completedAt?: number;
	completionAudit?: string;
	pausedReason?: GoalPausedReason;
	usageByMessage?: Record<string, number>;
	lastContinuationAt?: number;
};

export type GoalStateFile = {
	version: 1;
	sessions: Record<string, GoalEntry>;
};

export type GoalIntent =
	| { type: "show" }
	| { type: "set"; objective: string }
	| { type: "pause" }
	| { type: "resume" }
	| { type: "clear" };

export type GoalToastEffect = {
	type: "toast";
	title: string;
	message: string;
	variant: "success" | "warning" | "error" | "info";
};

export type GoalPromptEffect = {
	type: "prompt";
	text: string;
};

export type GoalEffect = GoalToastEffect | GoalPromptEffect;

export type GoalUsageEvent = {
	messageID: string;
	tokenTotal: number;
	timeUsedSeconds?: number;
	role?: string;
};

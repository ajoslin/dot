import type { GoalEntry } from "./goal-types.ts";

export function renderNoGoal(): string {
	return ["Usage: /goal <objective>", "No goal currently set."].join("\n");
}

export function renderGoalSet(entry: GoalEntry): string {
	return `Goal set: ${entry.objective}`;
}

export function renderGoalPaused(entry: GoalEntry): string {
	return `Goal paused${entry.pausedReason ? ` (${entry.pausedReason})` : ""}: ${entry.objective}`;
}

export function renderGoalResumed(entry: GoalEntry): string {
	return `Goal resumed: ${entry.objective}`;
}

export function renderGoalCleared(removed: boolean): string {
	return removed ? "Goal cleared." : "No goal to clear.";
}

export function renderGoalMissing(action: "pause" | "resume"): string {
	return `No goal to ${action}.`;
}

export function renderValidationError(message: string): string {
	return message;
}

function renderCommandHints(entry: GoalEntry): string {
	if (entry.status === "budget_limited") return "Commands: /goal clear";
	if (entry.status === "paused") return "Commands: /goal resume, /goal clear";
	if (entry.status === "complete") return "Commands: /goal clear";
	return "Commands: /goal pause, /goal clear";
}

export function renderGoalSummary(entry: GoalEntry): string {
	const lines = [
		"Goal",
		`Status: ${entry.status}`,
		`Objective: ${entry.objective}`,
		`Time used: ${entry.timeUsedSeconds}s`,
		`Tokens used: ${entry.tokensUsed}`,
	];
	if (entry.tokenBudget !== null) {
		lines.push(`Token budget: ${entry.tokenBudget}`);
		lines.push(`Remaining tokens: ${Math.max(0, entry.tokenBudget - entry.tokensUsed)}`);
	}
	if (entry.pausedReason) lines.push(`Paused reason: ${entry.pausedReason}`);
	if (entry.completedAt !== undefined) {
		lines.push(`Completed at: ${new Date(entry.completedAt).toISOString()}`);
	}
	if (entry.completionAudit) {
		lines.push(`Completion audit: ${entry.completionAudit}`);
	}
	lines.push(renderCommandHints(entry));
	return lines.join("\n");
}

import type { GoalEntry, GoalUsageEvent } from "./goal-types.ts";

export function validateTokenBudget(tokenBudget: number | null | undefined): void {
	if (tokenBudget == null) return;
	if (!Number.isFinite(tokenBudget) || tokenBudget <= 0) {
		throw new Error("Token budget must be positive");
	}
}

export function applyGoalUsage(
	entry: GoalEntry,
	usage: { tokensUsed?: number; timeUsedSeconds?: number },
	now: number,
): GoalEntry {
	const tokensUsed =
		usage.tokensUsed === undefined
			? entry.tokensUsed
			: Math.max(0, Math.floor(usage.tokensUsed));
	const timeUsedSeconds =
		usage.timeUsedSeconds === undefined
			? entry.timeUsedSeconds
			: Math.max(0, Math.floor(usage.timeUsedSeconds));

	const status =
		entry.tokenBudget !== null && tokensUsed >= entry.tokenBudget
			? "budget_limited"
			: entry.status;

	return {
		...entry,
		tokensUsed,
		timeUsedSeconds,
		status,
		updatedAt: now,
	};
}

export function applyGoalUsageEvent(
	entry: GoalEntry,
	usage: GoalUsageEvent,
	now: number,
): GoalEntry {
	if (usage.role && usage.role !== "assistant") return entry;
	const messageID = usage.messageID.trim();
	if (!messageID) return entry;
	const tokenTotal = Math.max(0, Math.floor(usage.tokenTotal));
	const previous = entry.usageByMessage?.[messageID] ?? 0;
	const delta = Math.max(0, tokenTotal - previous);
	if (delta === 0 && usage.timeUsedSeconds === undefined) {
		return {
			...entry,
			usageByMessage: {
				...(entry.usageByMessage ?? {}),
				[messageID]: Math.max(previous, tokenTotal),
			},
		};
	}

	return applyGoalUsage(
		{
			...entry,
			usageByMessage: {
				...(entry.usageByMessage ?? {}),
				[messageID]: Math.max(previous, tokenTotal),
			},
		},
		{
			tokensUsed: entry.tokensUsed + delta,
			timeUsedSeconds:
				usage.timeUsedSeconds === undefined
					? entry.timeUsedSeconds
					: entry.timeUsedSeconds +
						Math.max(0, Math.floor(usage.timeUsedSeconds)),
		},
		now,
	);
}

export function isBudgetLimited(entry: GoalEntry): boolean {
	return entry.tokenBudget !== null && entry.tokensUsed >= entry.tokenBudget;
}

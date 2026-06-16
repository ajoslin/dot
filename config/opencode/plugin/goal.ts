import { GoalOrchestrator } from "./goal/goal-orchestrator.ts";
import {
	getGoalSessionID,
	isGoalDeleteEvent,
	isGoalReadyEvent,
	parseGoalEvent,
	type GoalEventLike,
} from "./goal/goal-parse.ts";
import type { GoalEffect } from "./goal/goal-types.ts";
import { clearGoalEntry } from "./goal/goal-state.ts";
import { tool } from "@opencode-ai/plugin";

type GoalClient = {
	tui?: {
		showToast(input: {
			body: { title: string; message: string; variant: string };
		}): Promise<unknown>;
	};
	session?: {
		prompt(input: {
			path: { id: string };
			body: { parts: Array<{ type: "text"; text: string }> };
			query: { directory: string };
		}): Promise<unknown>;
	};
};

async function applyEffects(
	orchestrator: GoalOrchestrator,
	client: GoalClient,
	directory: string,
	sessionID: string | null,
	effects: GoalEffect[],
): Promise<void> {
	for (const effect of effects) {
		if (effect.type === "toast") {
			await client.tui?.showToast({
				body: {
					title: effect.title,
					message: effect.message,
					variant: effect.variant,
				},
			});
			continue;
		}

		if (effect.type === "prompt" && sessionID) {
			const goalId = orchestrator.getGoal(sessionID)?.goalId;
			try {
				await client.session?.prompt({
					path: { id: sessionID },
					body: { parts: [{ type: "text", text: effect.text }] },
					query: { directory },
				});
			} finally {
				orchestrator.markContinuationFinished(sessionID, goalId);
			}
		}
	}
}

/**
 * @type {import('@opencode-ai/plugin').Plugin}
 */
export const GoalPlugin = async ({
	directory,
	client,
}: {
	directory: string;
	client: GoalClient;
}) => {
	const readySessions = new Set<string>();
	const orchestrator = new GoalOrchestrator({
		directory,
		isSessionReady: (sessionID) => readySessions.has(sessionID),
	});

	return {
		tool: {
			get_goal: tool({
				description: "Get the current persistent goal for this OpenCode session.",
				args: {},
				async execute(_args, context) {
					return JSON.stringify({ goal: orchestrator.getGoal(context.sessionID) });
				},
			}),
			create_goal: tool({
				description:
					"Create a new active goal for this session ONLY when the user explicitly commands goal creation/setting and no goal exists. Explicit commands include bare /goal <objective>, /goal create <objective>, /goal set <objective>, /goal start <objective>, /goal: <objective>, or direct requests to invoke/call create_goal. Do not use for status checks, ambiguous requests, implied tasks, or ordinary work requests. Goals default to unlimited token budget.",
				args: {
					objective: tool.schema.string().describe("Explicit goal objective."),
				},
				async execute(args, context) {
					const result = orchestrator.createGoal(context.sessionID, args.objective, {
						tokenBudget: null,
					});
					if (!result.ok) throw new Error(result.error);
					return JSON.stringify({ goal: result.goal });
				},
			}),
			update_goal: tool({
				description:
					"Mark the entire current goal complete only when the full objective is actually done. Do not use after finishing a partial slice, subtask, checkpoint, or single work item. No other status updates are accepted.",
				args: {
					status: tool.schema.literal("complete"),
					audit: tool.schema
						.string()
						.describe("Non-empty completion audit explaining what was verified."),
				},
				async execute(args, context) {
					const result = orchestrator.completeGoal(context.sessionID, args.audit);
					if (!result.ok) throw new Error(result.error);
					return JSON.stringify({
						goal: result.goal,
						completionBudgetReport:
							result.goal.tokenBudget === null
								? null
								: {
										tokensUsed: result.goal.tokensUsed,
										tokenBudget: result.goal.tokenBudget,
										remainingTokens: Math.max(
											0,
											result.goal.tokenBudget - result.goal.tokensUsed,
										),
									},
					});
				},
			}),
		},
		event: async ({ event }: { event: GoalEventLike }) => {
			const sessionID = getGoalSessionID(event);

			if (isGoalDeleteEvent(event) && sessionID) {
				readySessions.delete(sessionID);
				clearGoalEntry(directory, sessionID);
				return event;
			}

			if (isInterruptEvent(event) && sessionID) {
				orchestrator.pauseGoal(sessionID, "interrupted");
				return event;
			}

			if (sessionID) {
				const usage = getUsageEvent(event);
				if (usage) orchestrator.recordUsage(sessionID, usage);
			}

			if (isGoalReadyEvent(event) && sessionID) {
				readySessions.add(sessionID);
				await applyEffects(
					orchestrator,
					client,
					directory,
					sessionID,
					orchestrator.replayQueued(sessionID),
				);
			}

			const intent = parseGoalEvent(event);
			if (!intent) {
				if (isGoalIdleEvent(event) && sessionID) {
					await applyEffects(
						orchestrator,
						client,
						directory,
						sessionID,
						orchestrator.handleIdle(sessionID),
					);
				}
				return event;
			}

			if (sessionID) readySessions.add(sessionID);
			await applyEffects(
				orchestrator,
				client,
				directory,
				sessionID,
				orchestrator.handleIntent(sessionID, intent),
			);

			return event;
		},
	};
};

export default GoalPlugin;

function isGoalIdleEvent(event: GoalEventLike): boolean {
	return (
		event?.type === "session.idle" ||
		(event?.type === "session.status" &&
			event?.properties?.status?.type === "idle")
	);
}

function isInterruptEvent(event: GoalEventLike): boolean {
	return (
		event?.type === "session.interrupt" ||
		event?.type === "session.interrupted" ||
		event?.type === "session.abort" ||
		event?.type === "session.cancelled" ||
		event?.type === "session.canceled" ||
		(event?.type === "session.status" &&
			(event?.properties?.status?.type === "interrupted" ||
				event?.properties?.status?.type === "cancelled" ||
				event?.properties?.status?.type === "canceled"))
	);
}

function isUserInstructionEvent(event: GoalEventLike): boolean {
	const role =
		event?.properties?.info?.role ??
		(typeof event?.properties?.message === "object"
			? event.properties.message.role
			: undefined);

	return (
		role === "user" &&
		(event?.type === "message.created" ||
			event?.type === "message.updated" ||
			event?.type === "session.message")
	);
}

function getUsageEvent(event: GoalEventLike) {
	if (event?.type !== "message.updated") return null;
	const info = event.properties?.info as
		| {
				id?: string;
				role?: string;
				tokens?: {
					input?: number;
					output?: number;
					reasoning?: number;
					cache?: { read?: number; write?: number };
				};
				time?: { created?: number; completed?: number };
		  }
		| undefined;
	if (!info || info.role !== "assistant" || typeof info.id !== "string") {
		return null;
	}
	const tokens = info.tokens;
	if (!tokens) return null;
	const tokenTotal =
		(tokens.input ?? 0) +
		(tokens.output ?? 0) +
		(tokens.reasoning ?? 0) +
		(tokens.cache?.read ?? 0) +
		(tokens.cache?.write ?? 0);
	const elapsed =
		typeof info.time?.created === "number" && typeof info.time.completed === "number"
			? Math.max(0, Math.floor((info.time.completed - info.time.created) / 1000))
			: undefined;
	return {
		messageID: info.id,
		role: info.role,
		tokenTotal,
		timeUsedSeconds: elapsed,
	};
}

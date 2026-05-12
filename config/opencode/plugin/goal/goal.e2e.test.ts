import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import GoalPlugin from "../goal.ts";
import { GoalOrchestrator, setGoalTokenBudget } from "./goal-orchestrator.ts";
import { getGoalEntry } from "./goal-state.ts";

type ToastRequest = {
	body: { title: string; message: string; variant: string };
};

let directory = "";

function createClient() {
	const toasts: ToastRequest[] = [];
	const prompts: unknown[] = [];
	const client = {
		tui: {
			async showToast(input: ToastRequest) {
				toasts.push(input);
				return { ok: true };
			},
		},
		session: {
			async prompt(input: unknown) {
				prompts.push(input);
				return { ok: true };
			},
		},
	};
	return { client, toasts, prompts };
}

describe("goal orchestrator and plugin e2e", () => {
	beforeEach(() => {
		directory = fs.mkdtempSync(path.join(os.tmpdir(), "goal-e2e-"));
	});

	afterEach(() => {
		fs.rmSync(directory, { recursive: true, force: true });
	});

	it("sets, reports, pauses, resumes, and clears through plugin events", async () => {
		const { client, toasts, prompts } = createClient();
		const plugin = await GoalPlugin({ directory, client });
		const sessionID = "session-1";

		await plugin.event({
			event: {
				type: "session.ready",
				properties: { sessionID },
			},
		});
		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "ship the plugin" },
			},
		});

		expect(getGoalEntry(directory, sessionID)?.objective).toBe("ship the plugin");
		expect(getGoalEntry(directory, sessionID)?.status).toBe("active");

		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "" },
			},
		});
		expect(toasts.at(-1)?.body.message).toContain("Status: active");
		expect(prompts.length).toBe(0);

		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "pause" },
			},
		});
		expect(getGoalEntry(directory, sessionID)?.status).toBe("paused");

		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "resume" },
			},
		});
		expect(getGoalEntry(directory, sessionID)?.status).toBe("active");

		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "clear" },
			},
		});
		expect(getGoalEntry(directory, sessionID)).toBeNull();
	});

	it("continues active goals on idle and respects pause, interrupt, and delete", async () => {
		const { client, prompts } = createClient();
		const plugin = await GoalPlugin({ directory, client });
		const sessionID = "session-idle";

		await plugin.event({
			event: { type: "session.ready", properties: { sessionID } },
		});
		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "finish idle work" },
			},
		});

		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		expect(prompts.length).toBe(1);

		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "pause" },
			},
		});
		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		expect(prompts.length).toBe(1);

		await plugin.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "resume" },
			},
		});
		const promptsAfterResume = prompts.length;
		await plugin.event({ event: { type: "session.interrupt", properties: { sessionID } } });
		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		expect(prompts.length).toBe(promptsAfterResume);

		await plugin.event({
			event: {
				type: "message.updated",
				properties: {
					sessionID,
					info: { role: "user" },
					messageID: "user-after-interrupt",
				},
			},
		});
		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		expect(prompts.length).toBe(promptsAfterResume);
		expect(getGoalEntry(directory, sessionID)?.status).toBe("paused");
		expect(getGoalEntry(directory, sessionID)?.pausedReason).toBe("interrupted");

		await plugin.event({
			event: { type: "session.deleted", properties: { info: { id: sessionID } } },
		});
		expect(getGoalEntry(directory, sessionID)).toBeNull();
	});

	it("queues set-goal intent until session readiness", () => {
		const ready = new Set<string>();
		const orchestrator = new GoalOrchestrator({
			directory,
			now: () => 100,
			id: () => "goal-queued",
			isSessionReady: (sessionID) => ready.has(sessionID),
		});

		const effects = orchestrator.handleIntent("session-queued", {
			type: "set",
			objective: "queued work",
		});
		expect(effects[0]?.type).toBe("toast");
		expect(getGoalEntry(directory, "session-queued")).toBeNull();

		ready.add("session-queued");
		orchestrator.replayQueued("session-queued");

		expect(getGoalEntry(directory, "session-queued")?.objective).toBe(
			"queued work",
		);
	});

	it("replace resets usage while same objective preserves usage", () => {
		const orchestrator = new GoalOrchestrator({
			directory,
			now: () => 100,
			id: () => "goal-1",
		});

		orchestrator.handleIntent("session-usage", {
			type: "set",
			objective: "same",
		});
		orchestrator.updateUsage("session-usage", {
			tokensUsed: 9,
			timeUsedSeconds: 5,
		});
		orchestrator.handleIntent("session-usage", {
			type: "set",
			objective: "same",
		});
		expect(getGoalEntry(directory, "session-usage")?.tokensUsed).toBe(9);

		orchestrator.handleIntent("session-usage", {
			type: "set",
			objective: "different",
		});
		expect(getGoalEntry(directory, "session-usage")?.tokensUsed).toBe(0);
		expect(getGoalEntry(directory, "session-usage")?.timeUsedSeconds).toBe(0);
	});

	it("rejects invalid objectives and token budgets", () => {
		const orchestrator = new GoalOrchestrator({ directory });
		const tooLong = "x".repeat(4001);
		const effects = orchestrator.handleIntent("session-invalid", {
			type: "set",
			objective: tooLong,
		});
		expect(effects[0]?.type).toBe("toast");
		expect(getGoalEntry(directory, "session-invalid")).toBeNull();

		orchestrator.handleIntent("session-invalid", {
			type: "set",
			objective: "valid",
		});
		expect(() => setGoalTokenBudget(directory, "session-invalid", 0)).toThrow(
			"Token budget must be positive",
		);
	});

	it("moves to budget_limited when usage crosses budget", () => {
		const orchestrator = new GoalOrchestrator({ directory, now: () => 100 });
		orchestrator.handleIntent("session-budget", {
			type: "set",
			objective: "budgeted work",
		});
		setGoalTokenBudget(directory, "session-budget", 10, 101);
		orchestrator.updateUsage("session-budget", { tokensUsed: 10 });

		expect(getGoalEntry(directory, "session-budget")?.status).toBe(
			"budget_limited",
		);
	});

	it("completes only through audited update_goal semantics", () => {
		const orchestrator = new GoalOrchestrator({
			directory,
			now: () => 100,
			id: () => "goal-complete",
		});
		orchestrator.handleIntent("session-complete", {
			type: "set",
			objective: "complete me",
		});

		expect(orchestrator.completeGoal("session-complete", "").ok).toBe(false);
		const result = orchestrator.completeGoal(
			"session-complete",
			"verified objective is complete",
		);
		expect(result.ok).toBe(true);
		expect(getGoalEntry(directory, "session-complete")?.status).toBe("complete");
		expect(
			orchestrator.handleIdle("session-complete").some((effect) => effect.type === "prompt"),
		).toBe(false);
	});

	it("resume emits rich continuation and budget limit prompt only once", () => {
		const orchestrator = new GoalOrchestrator({
			directory,
			now: () => 100_000,
			id: () => "goal-rich",
		});
		orchestrator.handleIntent("session-rich", {
			type: "set",
			objective: "ship rich prompt",
		});
		orchestrator.pauseGoal("session-rich", "interrupted");
		const resumeEffects = orchestrator.resumeGoal("session-rich");
		const resumePrompt = resumeEffects.find((effect) => effect.type === "prompt");
		expect(resumePrompt?.type).toBe("prompt");
		if (resumePrompt?.type === "prompt") {
			expect(resumePrompt.text).toContain("<untrusted_objective>");
			expect(resumePrompt.text).toContain("update_goal");
			expect(resumePrompt.text).toContain("non-empty audit");
			expect(resumePrompt.text).toContain("Slice completion is progress, not goal completion");
			expect(resumePrompt.text).toContain("no remaining slices exist");
			expect(resumePrompt.text).toContain("leave the active goal open");
		}
		orchestrator.markContinuationFinished("session-rich", "goal-rich");

		setGoalTokenBudget(directory, "session-rich", 1, 100_001);
		orchestrator.updateUsage("session-rich", { tokensUsed: 1 });
		const first = orchestrator.handleIdle("session-rich");
		const second = orchestrator.handleIdle("session-rich");
		expect(first.some((effect) => effect.type === "prompt")).toBe(true);
		expect(second.some((effect) => effect.type === "prompt")).toBe(false);
	});

	it("records idempotent assistant usage deltas", () => {
		const orchestrator = new GoalOrchestrator({ directory, now: () => 100 });
		orchestrator.handleIntent("session-delta", {
			type: "set",
			objective: "count tokens",
		});
		orchestrator.recordUsage("session-delta", {
			messageID: "assistant-1",
			role: "assistant",
			tokenTotal: 10,
		});
		orchestrator.recordUsage("session-delta", {
			messageID: "assistant-1",
			role: "assistant",
			tokenTotal: 10,
		});
		orchestrator.recordUsage("session-delta", {
			messageID: "assistant-1",
			role: "assistant",
			tokenTotal: 13,
		});

		expect(getGoalEntry(directory, "session-delta")?.tokensUsed).toBe(13);
	});

	it("dedupes idle continuation across plugin instances", async () => {
		const first = createClient();
		const second = createClient();
		const pluginA = await GoalPlugin({ directory, client: first.client });
		const pluginB = await GoalPlugin({ directory, client: second.client });
		const sessionID = "session-duplicate-idle";

		await pluginA.event({
			event: { type: "session.ready", properties: { sessionID } },
		});
		await pluginA.event({
			event: {
				type: "command.executed",
				properties: { name: "goal", sessionID, arguments: "dedupe idle" },
			},
		});

		await pluginA.event({
			event: { type: "session.idle", properties: { sessionID } },
		});
		await pluginB.event({
			event: {
				type: "session.status",
				properties: { sessionID, status: { type: "idle" } },
			},
		});

		expect(first.prompts.length + second.prompts.length).toBe(1);
		expect(getGoalEntry(directory, sessionID)?.lastContinuationAt).toBeGreaterThan(0);
	});
});

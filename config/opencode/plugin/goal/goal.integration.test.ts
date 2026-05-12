import { describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import {
	createGoalSession,
	hasOpencodeCli,
	restoreHome,
	runGoalCommand,
	startGoalRuntime,
	type StartedGoalRuntime,
	waitForGoalEvent,
	withGoalLiveRuntime,
} from "./opencode-test-adapter.ts";
import type { GoalEntry } from "./goal-types.ts";
import GoalPlugin from "../goal.ts";

export type GoalIntegrationResult = {
	scenario: string;
	passed: boolean;
	observedEvents: string[];
	stateAssertions: string[];
	qualitativeAssertions: string[];
	failureReason?: string;
};

type GoalStateFile = {
	version?: 1;
	sessions: Record<string, GoalEntry>;
};

const LIVE_TEST_TIMEOUT_MS = 25_000;
const WAIT_TIMEOUT_MS = 8_000;
const WAIT_INTERVAL_MS = 50;

const liveIt = hasOpencodeCli() ? it : it.skip;

function getStatePath(workspaceDir: string): string {
	return path.join(workspaceDir, ".opencode", "state", "goals.json");
}

function readState(workspaceDir: string): GoalStateFile {
	const statePath = getStatePath(workspaceDir);
	if (!fs.existsSync(statePath)) return { sessions: {} };
	return JSON.parse(fs.readFileSync(statePath, "utf-8")) as GoalStateFile;
}

async function waitFor(condition: () => boolean, timeoutMs = WAIT_TIMEOUT_MS) {
	const startedAt = Date.now();
	while (Date.now() - startedAt < timeoutMs) {
		if (condition()) return;
		await Bun.sleep(WAIT_INTERVAL_MS);
	}
	throw new Error(`Condition not met within ${timeoutMs}ms`);
}

describe("goal real OpenCode integration harness", () => {
	liveIt(
		"registers goal model tools in a real OpenCode runtime",
		async () => {
			await withGoalLiveRuntime(async ({ client, workspaceDir }) => {
				const ids = await client.tool.ids({
					query: { directory: workspaceDir },
					throwOnError: true,
				});
				expect(ids.data).toContain("get_goal");
				expect(ids.data).toContain("create_goal");
				expect(ids.data).toContain("update_goal");
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	liveIt(
		"emits real command events and writes versioned state",
		async () => {
			await withGoalLiveRuntime(async ({ client, workspaceDir }) => {
				const sessionID = await createGoalSession(client, workspaceDir);
				const observedCommand = waitForGoalEvent(
					client,
					workspaceDir,
					(event) =>
						event.type === "command.executed" &&
						event.properties.sessionID === sessionID &&
						event.properties.name === "goal",
				);

				await runGoalCommand(client, workspaceDir, sessionID, "observe events");
				const event = await observedCommand;
				expect(event.type).toBe("command.executed");

				await waitFor(() => {
					const state = readState(workspaceDir);
					return (
						state.version === 1 &&
						state.sessions[sessionID]?.objective === "observe events"
					);
				});
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	liveIt(
		"runs command lifecycle through a real OpenCode runtime",
		async () => {
			await withGoalLiveRuntime(async ({ client, workspaceDir }) => {
				const commandList = await client.command.list({
					query: { directory: workspaceDir },
					throwOnError: true,
				});
				expect(commandList.data.some((command) => command.name === "goal")).toBe(
					true,
				);

				const sessionID = await createGoalSession(client, workspaceDir);
				const objective = "write a short plan";

				await runGoalCommand(client, workspaceDir, sessionID, objective);
				await waitFor(() => {
					const entry = readState(workspaceDir).sessions[sessionID];
					return entry?.objective === objective && entry.status === "active";
				});

				await runGoalCommand(client, workspaceDir, sessionID, "");
				expect(readState(workspaceDir).sessions[sessionID]?.objective).toBe(
					objective,
				);

				await runGoalCommand(client, workspaceDir, sessionID, "pause");
				await waitFor(
					() => readState(workspaceDir).sessions[sessionID]?.status === "paused",
				);

				await runGoalCommand(client, workspaceDir, sessionID, "resume");
				await waitFor(
					() => readState(workspaceDir).sessions[sessionID]?.status === "active",
				);

				await runGoalCommand(client, workspaceDir, sessionID, "clear");
				await waitFor(
					() => readState(workspaceDir).sessions[sessionID] === undefined,
				);

				await runGoalCommand(client, workspaceDir, sessionID, "clear");
				expect(readState(workspaceDir).sessions[sessionID]).toBeUndefined();
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	liveIt(
		"recovers malformed persisted state while preserving valid sessions",
		async () => {
			await withGoalLiveRuntime(async ({ client, workspaceDir }) => {
				const statePath = getStatePath(workspaceDir);
				fs.mkdirSync(path.dirname(statePath), { recursive: true });
				fs.writeFileSync(
					statePath,
					JSON.stringify({
						sessions: {
							bad: { objective: "" },
							other: {
								goalId: "goal-other",
								threadId: "other",
								objective: "existing goal",
								status: "paused",
								tokenBudget: null,
								tokensUsed: 3,
								timeUsedSeconds: 1,
								createdAt: 1,
								updatedAt: 2,
							},
						},
					}),
				);

				const sessionID = await createGoalSession(client, workspaceDir);
				await runGoalCommand(client, workspaceDir, sessionID, "new goal");

				await waitFor(() => {
					const state = readState(workspaceDir);
					return (
						state.sessions.bad === undefined &&
						state.sessions.other?.objective === "existing goal" &&
						state.sessions[sessionID]?.objective === "new goal"
					);
				});
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	liveIt(
		"rejects invalid commands without mutating state in a real runtime",
		async () => {
			await withGoalLiveRuntime(async ({ client, workspaceDir }) => {
				const sessionID = await createGoalSession(client, workspaceDir);

				await runGoalCommand(client, workspaceDir, sessionID, "pause");
				await runGoalCommand(client, workspaceDir, sessionID, "resume");
				await runGoalCommand(client, workspaceDir, sessionID, "");
				expect(readState(workspaceDir).sessions[sessionID]).toBeUndefined();

				await runGoalCommand(client, workspaceDir, sessionID, "x".repeat(4001));
				expect(readState(workspaceDir).sessions[sessionID]).toBeUndefined();
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	liveIt(
		"clears persisted state when the session is deleted",
		async () => {
			await withGoalLiveRuntime(async ({ client, workspaceDir }) => {
				const sessionID = await createGoalSession(client, workspaceDir);
				await runGoalCommand(client, workspaceDir, sessionID, "delete me");
				await waitFor(
					() => readState(workspaceDir).sessions[sessionID]?.objective === "delete me",
				);

				await client.session.delete({
					path: { id: sessionID },
					query: { directory: workspaceDir },
					throwOnError: true,
				});

				await waitFor(
					() => readState(workspaceDir).sessions[sessionID] === undefined,
				);
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	liveIt(
		"recovers an active goal after runtime restart",
		async () => {
			const workspaceDir = fs.mkdtempSync(path.join(os.tmpdir(), "goal-restart-"));
			const fakeHome = fs.mkdtempSync(path.join(os.tmpdir(), "goal-home-"));
			const previousHome = process.env.HOME;
			let runtime: StartedGoalRuntime | null = null;

			process.env.HOME = fakeHome;
			try {
				runtime = await startGoalRuntime();
				const sessionID = await createGoalSession(runtime.client, workspaceDir);
				await runGoalCommand(
					runtime.client,
					workspaceDir,
					sessionID,
					"restart-safe goal",
				);
				await waitFor(
					() =>
						readState(workspaceDir).sessions[sessionID]?.objective ===
						"restart-safe goal",
				);

				runtime.server.close();
				runtime = await startGoalRuntime();

				await runGoalCommand(runtime.client, workspaceDir, sessionID, "");
				expect(readState(workspaceDir).sessions[sessionID]?.status).toBe(
					"active",
				);
				expect(readState(workspaceDir).sessions[sessionID]?.objective).toBe(
					"restart-safe goal",
				);
			} finally {
				runtime?.server.close();
				fs.rmSync(workspaceDir, { recursive: true, force: true });
				fs.rmSync(fakeHome, { recursive: true, force: true });
				restoreHome(previousHome);
			}
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	it("executes registered goal tool handlers with OpenCode tool context semantics", async () => {
		const workspaceDir = fs.mkdtempSync(path.join(os.tmpdir(), "goal-tools-"));
		const toasts: unknown[] = [];
		const prompts: unknown[] = [];
		const plugin = await GoalPlugin({
			directory: workspaceDir,
			client: {
				tui: { async showToast(input: unknown) { toasts.push(input); } },
				session: { async prompt(input: unknown) { prompts.push(input); } },
			},
		});
		const context = {
			sessionID: "tool-session",
			messageID: "tool-message",
			agent: "build",
			directory: workspaceDir,
			worktree: workspaceDir,
			abort: new AbortController().signal,
			metadata() {},
			ask() {
				throw new Error("unexpected permission request");
			},
		};

		try {
			const created = JSON.parse(
				await plugin.tool.create_goal.execute(
					{ objective: "finish through tools" },
					context as never,
				),
			);
			expect(created.goal.objective).toBe("finish through tools");
			expect(created.goal.tokenBudget).toBeNull();

			await expect(
				plugin.tool.create_goal.execute(
					{ objective: "second goal" },
					context as never,
				),
			).rejects.toThrow("already exists");

			const current = JSON.parse(
				await plugin.tool.get_goal.execute({}, context as never),
			);
			expect(current.goal.status).toBe("active");

			await expect(
				plugin.tool.update_goal.execute(
					{ status: "complete", audit: "" },
					context as never,
				),
			).rejects.toThrow("Completion audit is required");

			const completed = JSON.parse(
				await plugin.tool.update_goal.execute(
					{
						status: "complete",
						audit: "verified all requested work is complete",
					},
					context as never,
				),
			);
			expect(completed.goal.status).toBe("complete");
			expect(completed.goal.completionAudit).toContain("verified");
			expect(completed.completionBudgetReport).toBeNull();
			expect(toasts.length).toBe(0);
			expect(prompts.length).toBe(0);
		} finally {
			fs.rmSync(workspaceDir, { recursive: true, force: true });
		}
	});

	it("documents the compact result contract expected from real runtime scenarios", () => {
		const result: GoalIntegrationResult = {
			scenario: "start and persist",
			passed: true,
			observedEvents: ["command.executed"],
			stateAssertions: ["goal state persisted"],
			qualitativeAssertions: ["status command does not submit prompt text"],
		};

		expect(result.passed).toBe(true);
	});
});

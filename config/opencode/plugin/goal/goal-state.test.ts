import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import {
	clearGoalEntry,
	getGoalEntry,
	getGoalStatePath,
	putGoalEntry,
	readGoalState,
} from "./goal-state.ts";
import type { GoalEntry } from "./goal-types.ts";

let directory = "";

function entry(overrides: Partial<GoalEntry> = {}): GoalEntry {
	return {
		goalId: "goal-1",
		threadId: "session-1",
		objective: "finish implementation",
		status: "active",
		tokenBudget: null,
		tokensUsed: 0,
		timeUsedSeconds: 0,
		createdAt: 1,
		updatedAt: 2,
		...overrides,
	};
}

describe("goal state", () => {
	beforeEach(() => {
		directory = fs.mkdtempSync(path.join(os.tmpdir(), "goal-state-"));
	});

	afterEach(() => {
		fs.rmSync(directory, { recursive: true, force: true });
	});

	it("persists and clears entries", () => {
		expect(putGoalEntry(directory, "session-1", entry())).toBe(true);
		expect(getGoalEntry(directory, "session-1")?.objective).toBe(
			"finish implementation",
		);
		expect(clearGoalEntry(directory, "session-1")).toBe(true);
		expect(clearGoalEntry(directory, "session-1")).toBe(false);
		expect(getGoalEntry(directory, "session-1")).toBeNull();
	});

	it("normalizes malformed state and preserves valid sessions", () => {
		const statePath = getGoalStatePath(directory);
		fs.mkdirSync(path.dirname(statePath), { recursive: true });
		fs.writeFileSync(
			statePath,
			JSON.stringify({
				sessions: {
					bad: { objective: "" },
					good: entry({ threadId: "good", tokensUsed: -5 }),
				},
			}),
		);

		const state = readGoalState(directory);
		expect(state.sessions.bad).toBeUndefined();
		expect(state.sessions.good?.tokensUsed).toBe(0);
	});

	it("fails closed on malformed json", () => {
		const statePath = getGoalStatePath(directory);
		fs.mkdirSync(path.dirname(statePath), { recursive: true });
		fs.writeFileSync(statePath, "{not-json");

		expect(readGoalState(directory)).toEqual({ version: 1, sessions: {} });
	});

	it("migrates legacy state and normalizes optional fields", () => {
		const statePath = getGoalStatePath(directory);
		fs.mkdirSync(path.dirname(statePath), { recursive: true });
		fs.writeFileSync(
			statePath,
			JSON.stringify({
				sessions: {
					good: entry({
						threadId: "good",
						status: "complete",
						completedAt: 5,
						completionAudit: " verified ",
						pausedReason: "bogus" as never,
						usageByMessage: { a: 3, b: -2 },
					}),
				},
			}),
		);

		const state = readGoalState(directory);
		expect(state.version).toBe(1);
		expect(state.sessions.good?.completionAudit).toBe("verified");
		expect(state.sessions.good?.pausedReason).toBeUndefined();
		expect(state.sessions.good?.usageByMessage).toEqual({ a: 3, b: 0 });
	});
});

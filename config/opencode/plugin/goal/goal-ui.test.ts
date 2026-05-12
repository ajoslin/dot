import { describe, expect, it } from "bun:test";
import { renderGoalSummary, renderNoGoal } from "./goal-ui.ts";
import type { GoalEntry } from "./goal-types.ts";

function entry(overrides: Partial<GoalEntry> = {}): GoalEntry {
	return {
		goalId: "goal-1",
		threadId: "session-1",
		objective: "finish implementation",
		status: "active",
		tokenBudget: null,
		tokensUsed: 12,
		timeUsedSeconds: 3,
		createdAt: 1,
		updatedAt: 2,
		...overrides,
	};
}

describe("goal ui", () => {
	it("renders no-goal usage", () => {
		expect(renderNoGoal()).toContain("Usage: /goal <objective>");
		expect(renderNoGoal()).toContain("No goal currently set.");
	});

	it("renders active summary with usage", () => {
		const summary = renderGoalSummary(entry());
		expect(summary).toContain("Goal");
		expect(summary).toContain("Status: active");
		expect(summary).toContain("Objective: finish implementation");
		expect(summary).toContain("Time used: 3s");
		expect(summary).toContain("Tokens used: 12");
		expect(summary).toContain("/goal pause");
	});

	it("limits budget_limited hints to clear", () => {
		const summary = renderGoalSummary(
			entry({ status: "budget_limited", tokenBudget: 12 }),
		);
		expect(summary).toContain("Token budget: 12");
		expect(summary).toContain("Commands: /goal clear");
		expect(summary).not.toContain("/goal pause");
	});
});

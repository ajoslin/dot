import { describe, expect, it } from "bun:test";
import { parseGoalEvent, parseGoalText } from "./goal-parse.ts";

describe("goal parser", () => {
	it("parses bare goal command", () => {
		expect(parseGoalText("/goal")).toEqual({ type: "show" });
		expect(parseGoalText("  /goal   ")).toEqual({ type: "show" });
	});

	it("recognizes control words case-insensitively", () => {
		expect(parseGoalText("/goal CLEAR")).toEqual({ type: "clear" });
		expect(parseGoalText("/goal Pause")).toEqual({ type: "pause" });
		expect(parseGoalText("/goal resume")).toEqual({ type: "resume" });
	});

	it("keeps mentions and other text as objective text", () => {
		expect(parseGoalText("/goal fix @workspace regression")).toEqual({
			type: "set",
			objective: "fix @workspace regression",
		});
		expect(parseGoalText("/goal clear the queue")).toEqual({
			type: "set",
			objective: "clear the queue",
		});
	});

	it("parses command.executed name and arguments", () => {
		expect(
			parseGoalEvent({
				type: "command.executed",
				properties: { name: "goal", arguments: "ship it" },
			}),
		).toEqual({ type: "set", objective: "ship it" });
	});

	it("ignores unrelated input", () => {
		expect(parseGoalText("/goals ship")).toBeNull();
		expect(parseGoalEvent({ type: "message.updated", properties: {} })).toBeNull();
	});
});

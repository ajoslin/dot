import type { GoalIntent } from "./goal-types.ts";

const GOAL_COMMAND = "/goal";
const CONTROLS = new Set(["clear", "pause", "resume"]);

export function parseGoalText(input: string): GoalIntent | null {
	const trimmed = input.trim();
	if (!trimmed) return null;

	if (trimmed === GOAL_COMMAND) return { type: "show" };
	if (!trimmed.startsWith(`${GOAL_COMMAND} `)) return null;

	const argument = trimmed.slice(GOAL_COMMAND.length).trim();
	if (!argument) return { type: "show" };

	const lower = argument.toLowerCase();
	if (CONTROLS.has(lower)) {
		return { type: lower as "clear" | "pause" | "resume" };
	}

	return { type: "set", objective: argument };
}

export type GoalEventLike = {
	type?: string;
	properties?: Record<string, unknown> & {
		command?: string;
		name?: string;
		arguments?: string;
		message?: string | { role?: string };
		text?: string;
		sessionID?: string;
		info?: { sessionID?: string; id?: string; role?: string };
		part?: { sessionID?: string };
		status?: { type?: string };
	};
};

export function parseGoalEvent(event: GoalEventLike): GoalIntent | null {
	if (event?.type !== "command.executed") return null;
	const props = event.properties ?? {};

	const name = typeof props.name === "string" ? props.name.trim() : "";
	const args = typeof props.arguments === "string" ? props.arguments : "";
	if (name.toLowerCase() === "goal") {
		return parseGoalText(args ? `${GOAL_COMMAND} ${args}` : GOAL_COMMAND);
	}

	const command =
		typeof props.command === "string"
			? props.command
			: typeof props.message === "string"
				? props.message
				: typeof props.text === "string"
					? props.text
					: "";
	return parseGoalText(command);
}

export function getGoalSessionID(event: GoalEventLike): string | null {
	const direct = event?.properties?.sessionID;
	if (typeof direct === "string" && direct.trim()) return direct;

	const infoSessionID = event?.properties?.info?.sessionID;
	if (typeof infoSessionID === "string" && infoSessionID.trim()) {
		return infoSessionID;
	}

	const infoID = event?.properties?.info?.id;
	if (typeof infoID === "string" && infoID.trim()) return infoID;

	const partSessionID = event?.properties?.part?.sessionID;
	if (typeof partSessionID === "string" && partSessionID.trim()) {
		return partSessionID;
	}

	return null;
}

export function isGoalReadyEvent(event: GoalEventLike): boolean {
	return (
		event?.type === "session.ready" ||
		(event?.type === "session.status" &&
			event?.properties?.status?.type === "idle")
	);
}

export function isGoalDeleteEvent(event: GoalEventLike): boolean {
	return event?.type === "session.deleted";
}

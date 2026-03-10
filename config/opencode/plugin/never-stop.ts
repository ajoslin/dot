import { tool } from "@opencode-ai/plugin";
import { execFile } from "node:child_process";
import * as fs from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import {
	clearNeverStopPrompt,
	getNeverStopPrompt,
	getNeverStopSessionMeta,
	markNeverStopPromptSent,
	setNeverStopPrompt,
	touchNeverStopSessionActivity,
} from "./never-stop/never-stop-state.ts";

const DEFAULT_IDLE_DELAY_MS = 30_000;
const DEFAULT_SEND_COOLDOWN_MS = 60_000;
const DEFAULT_INTERRUPT_GRACE_MS = 5_000;
const DEFAULT_REINFORCE_PERIOD_MS = 45 * 60_000;
const DEFAULT_REINFORCE_TICK_MS = 60_000;
const DEFAULT_FAILURE_BACKOFF_BASE_MS = 5_000;
const DEFAULT_FAILURE_RESET_WINDOW_MS = 5 * 60_000;
const DEFAULT_MAX_CONSECUTIVE_FAILURES = 5;
const NEVER_STOP_COMMAND = "/never-stop";
const NEVER_STOP_CLEAR_COMMAND = "/never-stop-clear";
const NEVER_STOP_PRIMARY_SOUND = join(
	homedir(),
	".config/opencode/sounds/starcraft_recall.ogg",
);
const NEVER_STOP_FALLBACK_SOUND = join(
	homedir(),
	".config/opencode/sounds/18_monk_select.ogg",
);

type NeverStopCommand = { type: "set"; prompt: string } | { type: "clear" };

type EventLike = {
	type?: string;
	properties?: Record<string, unknown> & {
		sessionID?: string;
		command?: string;
		name?: string;
		arguments?: string;
		info?: { sessionID?: string; id?: string };
		part?: { sessionID?: string };
		status?: { type?: string };
		error?: { name?: string };
	};
};

type NeverStopTiming = {
	idleDelayMs: number;
	sendCooldownMs: number;
	interruptGraceMs: number;
	reinforcePeriodMs: number;
	reinforceTickMs: number;
	failureBackoffBaseMs: number;
	failureResetWindowMs: number;
	maxConsecutiveFailures: number;
};

type NeverStopMessagePart = {
	type?: string;
	name?: string;
	toolName?: string;
};

type NeverStopMessage = {
	info?: { role?: string };
	role?: string;
	parts?: NeverStopMessagePart[];
};

type NeverStopFailureState = {
	consecutiveFailures: number;
	lastFailureAt: number;
};

type NeverStopClient = {
	tui: {
		showToast(input: {
			body: { title: string; message: string; variant: string };
		}): Promise<unknown>;
	};
	session: {
		prompt(input: {
			path: { id: string };
			body: { parts: Array<{ type: "text"; text: string }> };
			query: { directory: string };
		}): Promise<unknown>;
		messages?: (input: {
			path: { id: string };
			query?: { directory?: string };
		}) => Promise<unknown>;
	};
};

type NeverStopContext = {
	directory: string;
	client: NeverStopClient;
};

function getSessionID(event: EventLike): string | null {
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

function parseDurationEnv(name: string, fallback: number): number {
	const raw = process.env[name];
	if (!raw) return fallback;
	const parsed = Number(raw);
	if (!Number.isFinite(parsed) || parsed < 0) return fallback;
	return Math.floor(parsed);
}

function getTimingConfig(): NeverStopTiming {
	return {
		idleDelayMs: parseDurationEnv(
			"NEVER_STOP_IDLE_DELAY_MS",
			DEFAULT_IDLE_DELAY_MS,
		),
		sendCooldownMs: parseDurationEnv(
			"NEVER_STOP_SEND_COOLDOWN_MS",
			DEFAULT_SEND_COOLDOWN_MS,
		),
		interruptGraceMs: parseDurationEnv(
			"NEVER_STOP_INTERRUPT_GRACE_MS",
			DEFAULT_INTERRUPT_GRACE_MS,
		),
		reinforcePeriodMs: parseDurationEnv(
			"NEVER_STOP_REINFORCE_PERIOD_MS",
			DEFAULT_REINFORCE_PERIOD_MS,
		),
		reinforceTickMs: parseDurationEnv(
			"NEVER_STOP_REINFORCE_TICK_MS",
			DEFAULT_REINFORCE_TICK_MS,
		),
		failureBackoffBaseMs: parseDurationEnv(
			"NEVER_STOP_FAILURE_BACKOFF_BASE_MS",
			DEFAULT_FAILURE_BACKOFF_BASE_MS,
		),
		failureResetWindowMs: parseDurationEnv(
			"NEVER_STOP_FAILURE_RESET_WINDOW_MS",
			DEFAULT_FAILURE_RESET_WINDOW_MS,
		),
		maxConsecutiveFailures: parseDurationEnv(
			"NEVER_STOP_MAX_CONSECUTIVE_FAILURES",
			DEFAULT_MAX_CONSECUTIVE_FAILURES,
		),
	};
}

function normalizeMessages(response: unknown): NeverStopMessage[] {
	if (Array.isArray(response)) {
		return response as NeverStopMessage[];
	}

	if (typeof response === "object" && response !== null && "data" in response) {
		const data = (response as { data?: unknown }).data;
		if (Array.isArray(data)) {
			return data as NeverStopMessage[];
		}
	}

	return [];
}

function hasUnansweredQuestion(messages: NeverStopMessage[]): boolean {
	if (!messages || messages.length === 0) return false;

	for (let i = messages.length - 1; i >= 0; i--) {
		const message = messages[i];
		const role = message.info?.role ?? message.role;

		if (role === "user") return false;

		if (role === "assistant" && Array.isArray(message.parts)) {
			const hasQuestion = message.parts.some((part) => {
				const type = part.type;
				const toolName = part.name ?? part.toolName;
				return (
					(type === "tool_use" || type === "tool-invocation") &&
					toolName === "question"
				);
			});
			return hasQuestion;
		}
	}

	return false;
}

function isIdleEvent(event: EventLike): boolean {
	if (event?.type === "session.idle") return true;
	return (
		event?.type === "session.status" &&
		event?.properties?.status?.type === "idle"
	);
}

function isActivityEvent(event: EventLike): boolean {
	return (
		event?.type === "message.updated" ||
		event?.type === "message.part.updated" ||
		event?.type === "command.executed" ||
		(event?.type === "session.status" &&
			event?.properties?.status?.type !== "idle")
	);
}

function isInterruptEvent(event: EventLike): boolean {
	if (event?.type === "session.interrupted" || event?.type === "session.abort") {
		return true;
	}
	if (event?.type === "session.error") {
		const errorName = event?.properties?.error?.name;
		if (errorName === "MessageAbortedError" || errorName === "AbortError") {
			return true;
		}
	}
	if (event?.type !== "command.executed") return false;

	const names = [
		normalizeCommandName(event?.properties?.name),
		normalizeCommandName(event?.properties?.command),
	];

	return names.some(
		(commandName) =>
			commandName === "session.interrupt" ||
			commandName === "session.abort" ||
			commandName === "interrupt" ||
			commandName === "abort",
	);
}

function parseNeverStopLine(rawLine: string | null | undefined): NeverStopCommand | null {
	if (typeof rawLine !== "string") return null;
	const line = rawLine.trim();
	if (!line.startsWith(NEVER_STOP_COMMAND)) return null;

	if (
		line === NEVER_STOP_CLEAR_COMMAND ||
		line.startsWith(`${NEVER_STOP_CLEAR_COMMAND} `)
	) {
		return { type: "clear" };
	}

	const setMatch = line.match(/^\/never-stop(?!-clear)\s+([\s\S]+)$/);
	if (!setMatch) return null;

	const prompt = setMatch[1].trim();
	if (!prompt) return null;
	return { type: "set", prompt };
}

function splitCommand(value: unknown): { name: string; remainder: string } | null {
	if (typeof value !== "string") return null;
	const trimmed = value.trim();
	if (!trimmed) return null;
	const match = trimmed.match(/^\/?([^\s]+)\s*([\s\S]*)$/);
	if (!match) return null;
	return { name: match[1], remainder: match[2] ?? "" };
}

function normalizeCommandName(value: unknown): string | null {
	const commandInfo = splitCommand(value);
	if (!commandInfo?.name) return null;
	return commandInfo.name.toLowerCase();
}

function extractCommandPrompt(
	properties: Record<string, unknown> | undefined,
): string | null {
	if (!properties || typeof properties !== "object") return null;

	const candidates = [
		properties.arguments,
		properties.args,
		properties.argument,
		properties.prompt,
		properties.input,
	];

	for (const candidate of candidates) {
		if (typeof candidate === "string") {
			const prompt = candidate.trim();
			if (prompt) return prompt;
			continue;
		}

		if (Array.isArray(candidate)) {
			const joined = candidate
				.filter((part): part is string => typeof part === "string")
				.map((part) => part.trim())
				.filter(Boolean)
				.join(" ");
			if (joined) return joined;
		}
	}

	return null;
}

function parseNeverStopCommand(event: EventLike): NeverStopCommand | null {
	if (event?.type !== "command.executed") return null;

	const structuredName = normalizeCommandName(event?.properties?.name);
	if (structuredName === "never-stop-clear") {
		return { type: "clear" };
	}
	if (structuredName === "never-stop") {
		const prompt = extractCommandPrompt(event?.properties);
		if (prompt) return { type: "set", prompt };
		return null;
	}

	const commandInfo = splitCommand(event?.properties?.command);
	const commandName = commandInfo?.name?.toLowerCase();
	if (commandName === "never-stop-clear") {
		return { type: "clear" };
	}
	if (commandName === "never-stop") {
		const prompt = extractCommandPrompt(event?.properties);
		if (prompt) return { type: "set", prompt };
		const remainder = commandInfo?.remainder.trim();
		if (remainder) return { type: "set", prompt: remainder };
		return null;
	}

	const direct = parseNeverStopLine(
		typeof event?.properties?.command === "string"
			? event.properties.command
			: null,
	);
	if (direct) return direct;

	return null;
}

async function showToast(
	client: NeverStopClient,
	message: string,
	variant = "info",
): Promise<void> {
	try {
		await client.tui.showToast({
			body: {
				title: "Never Stop",
				message,
				variant,
			},
		});
	} catch {
		// TUI may not be available
	}
}

async function playNeverStopInitiatedSound(): Promise<void> {
	const soundPath = fs.existsSync(NEVER_STOP_PRIMARY_SOUND)
		? NEVER_STOP_PRIMARY_SOUND
		: NEVER_STOP_FALLBACK_SOUND;
	if (!fs.existsSync(soundPath)) return;

	await new Promise<void>((resolve) => {
		execFile(
			"ffplay",
			[
				"-nodisp",
				"-autoexit",
				"-loglevel",
				"quiet",
				"-af",
				"volume=0.8",
				soundPath,
			],
			() => resolve(),
		);
	});
}

export const NeverStopPlugin = async (ctx: NeverStopContext) => {
	const timing = getTimingConfig();
	const idleTimers = new Map<string, ReturnType<typeof setTimeout>>();
	const reinforcementTimers = new Map<string, ReturnType<typeof setInterval>>();
	const inFlightSends = new Set<string>();
	const interruptDetectedAt = new Map<string, number>();
	const failureStates = new Map<string, NeverStopFailureState>();

	function cancelIdleTimer(sessionID: string): void {
		const timer = idleTimers.get(sessionID);
		if (timer) {
			clearTimeout(timer);
			idleTimers.delete(sessionID);
		}
	}

	function stopReinforcement(sessionID: string): void {
		const timer = reinforcementTimers.get(sessionID);
		if (timer) {
			clearInterval(timer);
			reinforcementTimers.delete(sessionID);
		}
	}

	function clearSessionRuntime(sessionID: string): void {
		cancelIdleTimer(sessionID);
		stopReinforcement(sessionID);
		inFlightSends.delete(sessionID);
		interruptDetectedAt.delete(sessionID);
		failureStates.delete(sessionID);
	}

	function resetFailureState(sessionID: string): void {
		failureStates.delete(sessionID);
	}

	function markSendFailure(sessionID: string): void {
		const now = Date.now();
		const existing = failureStates.get(sessionID);
		failureStates.set(sessionID, {
			consecutiveFailures: (existing?.consecutiveFailures ?? 0) + 1,
			lastFailureAt: now,
		});
	}

	function failureBackoffActive(sessionID: string): boolean {
		const failure = failureStates.get(sessionID);
		if (!failure || failure.consecutiveFailures <= 0) return false;

		const now = Date.now();
		if (now - failure.lastFailureAt >= timing.failureResetWindowMs) {
			failureStates.delete(sessionID);
			return false;
		}

		if (failure.consecutiveFailures >= timing.maxConsecutiveFailures) {
			return true;
		}

		const backoffMs =
			timing.failureBackoffBaseMs *
			2 ** Math.min(failure.consecutiveFailures - 1, 5);
		return now - failure.lastFailureAt < backoffMs;
	}

	async function hasPendingQuestion(sessionID: string): Promise<boolean> {
		if (typeof ctx.client.session.messages !== "function") return false;

		try {
			const messagesResponse = await ctx.client.session.messages({
				path: { id: sessionID },
				query: { directory: ctx.directory },
			});
			const messages = normalizeMessages(messagesResponse);
			return hasUnansweredQuestion(messages);
		} catch {
			return false;
		}
	}

	function canSend(sessionID: string, reason: "idle" | "reinforce"): boolean {
		const meta = getNeverStopSessionMeta(ctx.directory, sessionID);
		if (!meta?.prompt) return false;
		if (failureBackoffActive(sessionID)) return false;
		if (reason === "reinforce") {
			const lastSentAt = meta.lastSentAt ?? 0;
			if (Date.now() - lastSentAt < timing.sendCooldownMs) return false;
		}
		return true;
	}

	async function maybeSend(
		sessionID: string,
		reason: "idle" | "reinforce",
	): Promise<void> {
		if (!sessionID) return;
		if (inFlightSends.has(sessionID)) return;
		if (!canSend(sessionID, reason)) return;
		const interruptedAt = interruptDetectedAt.get(sessionID) ?? 0;
		if (Date.now() - interruptedAt < timing.interruptGraceMs) return;
		if (await hasPendingQuestion(sessionID)) return;

		const prompt = getNeverStopPrompt(ctx.directory, sessionID);
		if (!prompt) return;

		inFlightSends.add(sessionID);
		try {
			await ctx.client.session.prompt({
				path: { id: sessionID },
				body: {
					parts: [
						{
							type: "text",
							text:
								reason === "idle"
									? prompt
									: `[never-stop ${reason}]\n${prompt}`,
						},
					],
				},
				query: { directory: ctx.directory },
			});
			markNeverStopPromptSent(ctx.directory, sessionID);
			resetFailureState(sessionID);
		} catch {
			markSendFailure(sessionID);
			// Session may no longer exist.
		} finally {
			inFlightSends.delete(sessionID);
		}
	}

	function ensureReinforcement(sessionID: string): void {
		if (!getNeverStopPrompt(ctx.directory, sessionID)) {
			stopReinforcement(sessionID);
			return;
		}
		if (reinforcementTimers.has(sessionID)) return;

		const timer = setInterval(() => {
			const meta = getNeverStopSessionMeta(ctx.directory, sessionID);
			if (!meta?.prompt) {
				stopReinforcement(sessionID);
				return;
			}
			const lastSentAt = meta.lastSentAt ?? 0;
			if (lastSentAt > 0 && Date.now() - lastSentAt < timing.reinforcePeriodMs)
				return;
			void maybeSend(sessionID, "reinforce");
		}, timing.reinforceTickMs);
		reinforcementTimers.set(sessionID, timer);
	}

	function scheduleIdleSend(sessionID: string): void {
		if (!sessionID) return;
		if (!getNeverStopPrompt(ctx.directory, sessionID)) return;

		cancelIdleTimer(sessionID);
		const timer = setTimeout(() => {
			idleTimers.delete(sessionID);
			void maybeSend(sessionID, "idle");
		}, timing.idleDelayMs);
		idleTimers.set(sessionID, timer);
		ensureReinforcement(sessionID);
	}

	function createNeverStopSetTool() {
		return tool({
			description: "Set or update never-stop prompt for a session.",
			args: {
				sessionID: tool.schema.string().describe("Target session ID"),
				prompt: tool.schema.string().describe("Prompt to auto-send on idle"),
			},
			async execute(args: { sessionID: string; prompt: string }) {
				const ok = setNeverStopPrompt(
					ctx.directory,
					args.sessionID,
					args.prompt,
				);
				if (!ok) return "[never-stop] failed to set prompt";
				ensureReinforcement(args.sessionID);
				void playNeverStopInitiatedSound();
				return "[never-stop] prompt set";
			},
		});
	}

	function createNeverStopClearTool() {
		return tool({
			description: "Clear never-stop prompt for a session.",
			args: {
				sessionID: tool.schema.string().describe("Target session ID"),
			},
			async execute(args: { sessionID: string }) {
				const removed = clearNeverStopPrompt(ctx.directory, args.sessionID);
				clearSessionRuntime(args.sessionID);
				return removed
					? "[never-stop] prompt cleared"
					: "[never-stop] no prompt set";
			},
		});
	}

	function createNeverStopStatusTool() {
		return tool({
			description: "Check never-stop state for a session.",
			args: {
				sessionID: tool.schema.string().describe("Target session ID"),
			},
			async execute(args: { sessionID: string }) {
				const meta = getNeverStopSessionMeta(ctx.directory, args.sessionID);
				if (!meta?.prompt) {
					return "[never-stop] disabled for this session";
				}
				const lines = [
					"[never-stop] enabled",
					`  session: ${args.sessionID}`,
					`  prompt: ${meta.prompt}`,
					`  idle delay: ${timing.idleDelayMs / 1000}s`,
					`  reinforce: every ${timing.reinforcePeriodMs / 60_000}m`,
					`  cooldown: ${timing.sendCooldownMs / 1000}s`,
				];
				return lines.join("\n");
			},
		});
	}

	return {
		event: async ({ event }: { event: EventLike }) => {
			if (event.type === "session.deleted") {
				const deletedSessionID = getSessionID(event);
				if (!deletedSessionID) return event;
				clearNeverStopPrompt(ctx.directory, deletedSessionID);
				clearSessionRuntime(deletedSessionID);
				return event;
			}

			const sessionID = getSessionID(event);
			if (!sessionID) return event;

			if (isInterruptEvent(event)) {
				interruptDetectedAt.set(sessionID, Date.now());
				cancelIdleTimer(sessionID);
				return event;
			}

			const command = parseNeverStopCommand(event);
			if (command?.type === "set") {
				if (!command.prompt) {
					await showToast(
						ctx.client,
						`Usage: ${NEVER_STOP_COMMAND} <prompt>`,
						"warning",
					);
					return event;
				}
				const stored = setNeverStopPrompt(ctx.directory, sessionID, command.prompt);
				if (!stored) {
					await showToast(
						ctx.client,
						"Failed to store never-stop prompt",
						"error",
					);
					return event;
				}
				ensureReinforcement(sessionID);
				void playNeverStopInitiatedSound();
				await showToast(
					ctx.client,
					"Never-stop prompt set for this session",
					"success",
				);
				return event;
			}

			if (command?.type === "clear") {
				const removed = clearNeverStopPrompt(ctx.directory, sessionID);
				clearSessionRuntime(sessionID);
				await showToast(
					ctx.client,
					removed ? "Never-stop prompt cleared" : "No never-stop prompt set",
					"success",
				);
				return event;
			}

			if (isActivityEvent(event)) {
				touchNeverStopSessionActivity(ctx.directory, sessionID);
				cancelIdleTimer(sessionID);
				ensureReinforcement(sessionID);
				return event;
			}

			if (isIdleEvent(event)) {
				scheduleIdleSend(sessionID);
			}

			return event;
		},
		tool: {
			never_stop_set: createNeverStopSetTool(),
			never_stop_clear: createNeverStopClearTool(),
			never_stop_status: createNeverStopStatusTool(),
		},
	};
};

export default NeverStopPlugin;

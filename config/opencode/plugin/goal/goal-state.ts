import * as fs from "node:fs";
import * as path from "node:path";
import type {
	GoalEntry,
	GoalPausedReason,
	GoalStateFile,
	GoalStatus,
} from "./goal-types.ts";

const STATE_DIR = ".opencode/state";
const STATE_FILE = "goals.json";
const STATUSES = new Set<GoalStatus>([
	"active",
	"paused",
	"budget_limited",
	"complete",
]);
const PAUSED_REASONS = new Set<GoalPausedReason>([
	"user",
	"interrupted",
	"budget_limited",
]);

export function getGoalStatePath(directory: string): string {
	return path.join(directory, STATE_DIR, STATE_FILE);
}

function ensureStateDir(directory: string): void {
	fs.mkdirSync(path.join(directory, STATE_DIR), { recursive: true });
}

function finiteNumber(value: unknown, fallback = 0): number {
	return Number.isFinite(value) ? Number(value) : fallback;
}

function normalizeEntry(threadId: string, raw: unknown): GoalEntry | null {
	if (!raw || typeof raw !== "object") return null;
	const entry = raw as Partial<GoalEntry>;
	if (typeof entry.goalId !== "string" || !entry.goalId.trim()) return null;
	if (typeof entry.objective !== "string" || !entry.objective.trim()) return null;
	const status = STATUSES.has(entry.status as GoalStatus)
		? (entry.status as GoalStatus)
		: "active";
	const tokenBudget =
		entry.tokenBudget === null || entry.tokenBudget === undefined
			? null
			: Number.isFinite(entry.tokenBudget) && Number(entry.tokenBudget) > 0
				? Math.floor(Number(entry.tokenBudget))
				: null;

	const completedAt =
		entry.completedAt === undefined
			? undefined
			: Math.max(0, Math.floor(finiteNumber(entry.completedAt)));
	const completionAudit =
		typeof entry.completionAudit === "string" && entry.completionAudit.trim()
			? entry.completionAudit.trim()
			: undefined;
	const pausedReason = PAUSED_REASONS.has(entry.pausedReason as GoalPausedReason)
		? (entry.pausedReason as GoalPausedReason)
		: undefined;
	const usageByMessage: Record<string, number> = {};
	if (entry.usageByMessage && typeof entry.usageByMessage === "object") {
		for (const [messageID, value] of Object.entries(entry.usageByMessage)) {
			if (typeof messageID !== "string" || !messageID.trim()) continue;
			const total = Math.max(0, Math.floor(finiteNumber(value)));
			usageByMessage[messageID] = total;
		}
	}
	const lastContinuationAt =
		entry.lastContinuationAt === undefined
			? undefined
			: Math.max(0, Math.floor(finiteNumber(entry.lastContinuationAt)));

	return {
		goalId: entry.goalId.trim(),
		threadId:
			typeof entry.threadId === "string" && entry.threadId.trim()
				? entry.threadId
				: threadId,
		objective: entry.objective.trim(),
		status,
		tokenBudget,
		tokensUsed: Math.max(0, Math.floor(finiteNumber(entry.tokensUsed))),
		timeUsedSeconds: Math.max(
			0,
			Math.floor(finiteNumber(entry.timeUsedSeconds)),
		),
		createdAt: finiteNumber(entry.createdAt),
		updatedAt: finiteNumber(entry.updatedAt),
		...(completedAt !== undefined ? { completedAt } : {}),
		...(completionAudit !== undefined ? { completionAudit } : {}),
		...(pausedReason !== undefined ? { pausedReason } : {}),
		...(Object.keys(usageByMessage).length ? { usageByMessage } : {}),
		...(lastContinuationAt !== undefined ? { lastContinuationAt } : {}),
	};
}

function normalizeState(raw: unknown): {
	state: GoalStateFile;
	changed: boolean;
} {
	let changed = false;
	const sessions: Record<string, GoalEntry> = {};
	const rawSessions =
		raw &&
		typeof raw === "object" &&
		"sessions" in raw &&
		typeof (raw as { sessions?: unknown }).sessions === "object" &&
		(raw as { sessions?: unknown }).sessions !== null
			? ((raw as { sessions: Record<string, unknown> }).sessions)
			: {};

	for (const [sessionID, value] of Object.entries(rawSessions)) {
		const entry = normalizeEntry(sessionID, value);
		if (!entry) {
			changed = true;
			continue;
		}
		if (entry !== value) changed = true;
		sessions[sessionID] = entry;
	}

	const version = raw && typeof raw === "object" && (raw as { version?: unknown }).version === 1
		? 1
		: 1;
	if (!raw || typeof raw !== "object" || (raw as { version?: unknown }).version !== 1) {
		changed = true;
	}

	return { state: { version, sessions }, changed };
}

export function readGoalState(directory: string): GoalStateFile {
	const statePath = getGoalStatePath(directory);
	let raw: unknown = { version: 1, sessions: {} };

	if (fs.existsSync(statePath)) {
		try {
			raw = JSON.parse(fs.readFileSync(statePath, "utf-8"));
		} catch {
			raw = { version: 1, sessions: {} };
		}
	}

	const { state, changed } = normalizeState(raw);
	if (changed || raw === undefined) {
		writeGoalState(directory, state);
	}
	return state;
}

export function writeGoalState(directory: string, state: GoalStateFile): boolean {
	const statePath = getGoalStatePath(directory);
	const tempPath = `${statePath}.tmp`;
	try {
		ensureStateDir(directory);
		fs.writeFileSync(
			tempPath,
			JSON.stringify({ version: 1, sessions: state.sessions }, null, 2),
		);
		fs.renameSync(tempPath, statePath);
		return true;
	} catch {
		try {
			if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
		} catch {
			// best effort cleanup
		}
		return false;
	}
}

export function getGoalEntry(
	directory: string,
	sessionID: string | null | undefined,
): GoalEntry | null {
	if (!sessionID) return null;
	return readGoalState(directory).sessions[sessionID] ?? null;
}

export function putGoalEntry(
	directory: string,
	sessionID: string,
	entry: GoalEntry,
): boolean {
	const state = readGoalState(directory);
	state.sessions[sessionID] = entry;
	return writeGoalState(directory, state);
}

export function updateGoalEntry(
	directory: string,
	sessionID: string,
	update: (entry: GoalEntry) => GoalEntry | null,
): GoalEntry | null {
	const state = readGoalState(directory);
	const current = state.sessions[sessionID];
	if (!current) return null;
	const next = update(current);
	if (!next) return null;
	state.sessions[sessionID] = next;
	return writeGoalState(directory, state) ? next : null;
}

export function clearGoalEntry(
	directory: string,
	sessionID: string | null | undefined,
): boolean {
	if (!sessionID) return false;
	const state = readGoalState(directory);
	if (!state.sessions[sessionID]) return false;
	delete state.sessions[sessionID];
	return writeGoalState(directory, state);
}

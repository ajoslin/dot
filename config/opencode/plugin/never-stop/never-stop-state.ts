import * as fs from "node:fs";
import * as path from "node:path";

const STATE_DIR = ".opencode/state";
const CONFIG_FILE = "never-stop.json";
const STALE_MS = 30 * 24 * 60 * 60 * 1000;

export interface NeverStopEntry {
	prompt: string;
	updatedAt: number;
	lastSentAt: number;
	lastActivityAt: number;
}

export interface NeverStopState {
	sessions: Record<string, NeverStopEntry>;
}

function logStateError(message: string, error: unknown): void {
	const details = error instanceof Error ? error.message : String(error);
	console.warn(`[never-stop] ${message}: ${details}`);
}

function getStatePath(directory: string): string {
	return path.join(directory, STATE_DIR, CONFIG_FILE);
}

function ensureStateDir(directory: string): void {
	const stateDir = path.join(directory, STATE_DIR);
	if (!fs.existsSync(stateDir)) {
		fs.mkdirSync(stateDir, { recursive: true });
	}
}

function finiteTimestamp(value: unknown): number {
	return Number.isFinite(value) ? Number(value) : 0;
}

function normalizeEntry(entry: unknown): NeverStopEntry | null {
	if (!entry || typeof entry !== "object") return null;
	const candidate = entry as Partial<NeverStopEntry>;
	if (typeof candidate.prompt !== "string") return null;
	const prompt = candidate.prompt.trim();
	if (!prompt) return null;
	return {
		prompt,
		updatedAt: finiteTimestamp(candidate.updatedAt),
		lastSentAt: finiteTimestamp(candidate.lastSentAt),
		lastActivityAt: finiteTimestamp(candidate.lastActivityAt),
	};
}

function lastUsedAt(entry: NeverStopEntry): number {
	return Math.max(
		entry.updatedAt || 0,
		entry.lastSentAt || 0,
		entry.lastActivityAt || 0,
	);
}

function pruneStale(state: NeverStopState, now: number): boolean {
	let changed = false;
	const sessions = state.sessions || {};
	for (const [sessionID, rawEntry] of Object.entries(sessions)) {
		const entry = normalizeEntry(rawEntry);
		if (!entry) {
			delete sessions[sessionID];
			changed = true;
			continue;
		}
		const lastUsed = lastUsedAt(entry);
		if (lastUsed > 0 && now - lastUsed > STALE_MS) {
			delete sessions[sessionID];
			changed = true;
			continue;
		}
		sessions[sessionID] = entry;
	}
	state.sessions = sessions;
	return changed;
}

export function readNeverStopState(directory: string): NeverStopState {
	const statePath = getStatePath(directory);
	const now = Date.now();
	let state: NeverStopState = { sessions: {} };

	if (fs.existsSync(statePath)) {
		try {
			const parsed = JSON.parse(fs.readFileSync(statePath, "utf-8")) as {
				sessions?: unknown;
			};
			state = {
				sessions:
					parsed?.sessions && typeof parsed.sessions === "object"
						? (parsed.sessions as Record<string, NeverStopEntry>)
						: {},
			};
		} catch (error) {
			logStateError(`failed to parse state file at ${statePath}`, error);
			state = { sessions: {} };
		}
	}

	const changed = pruneStale(state, now);
	if (changed) {
		writeNeverStopState(directory, state);
	}
	return state;
}

export function writeNeverStopState(
	directory: string,
	state: NeverStopState,
): boolean {
	const statePath = getStatePath(directory);
	try {
		ensureStateDir(directory);
		fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
		return true;
	} catch (error) {
		logStateError(`failed to write state file at ${statePath}`, error);
		return false;
	}
}

export function getNeverStopPrompt(
	directory: string,
	sessionID: string | null | undefined,
): string | null {
	if (!sessionID) return null;
	const state = readNeverStopState(directory);
	const entry = normalizeEntry(state.sessions?.[sessionID]);
	return entry?.prompt ?? null;
}

export function setNeverStopPrompt(
	directory: string,
	sessionID: string | null | undefined,
	prompt: string,
): boolean {
	if (!sessionID) return false;
	if (typeof prompt !== "string") return false;
	const trimmed = prompt.trim();
	if (!trimmed) return false;

	const state = readNeverStopState(directory);
	const existing = normalizeEntry(state.sessions?.[sessionID]);
	const now = Date.now();
	state.sessions[sessionID] = {
		prompt: trimmed,
		updatedAt: now,
		lastSentAt: existing?.lastSentAt ?? 0,
		lastActivityAt: now,
	};
	return writeNeverStopState(directory, state);
}

export function clearNeverStopPrompt(
	directory: string,
	sessionID: string | null | undefined,
): boolean {
	if (!sessionID) return false;
	const state = readNeverStopState(directory);
	if (!state.sessions?.[sessionID]) return false;
	delete state.sessions[sessionID];
	return writeNeverStopState(directory, state);
}

export function touchNeverStopSessionActivity(
	directory: string,
	sessionID: string | null | undefined,
): boolean {
	if (!sessionID) return false;
	const state = readNeverStopState(directory);
	const entry = normalizeEntry(state.sessions?.[sessionID]);
	if (!entry) return false;
	entry.lastActivityAt = Date.now();
	state.sessions[sessionID] = entry;
	return writeNeverStopState(directory, state);
}

export function markNeverStopPromptSent(
	directory: string,
	sessionID: string | null | undefined,
): boolean {
	if (!sessionID) return false;
	const state = readNeverStopState(directory);
	const entry = normalizeEntry(state.sessions?.[sessionID]);
	if (!entry) return false;
	entry.lastSentAt = Date.now();
	state.sessions[sessionID] = entry;
	return writeNeverStopState(directory, state);
}

export function getNeverStopSessionMeta(
	directory: string,
	sessionID: string | null | undefined,
): NeverStopEntry | null {
	if (!sessionID) return null;
	const state = readNeverStopState(directory);
	return normalizeEntry(state.sessions?.[sessionID]);
}

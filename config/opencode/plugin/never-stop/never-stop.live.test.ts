import {
	createOpencode,
	type Event as OpencodeEvent,
	type OpencodeClient,
} from "@opencode-ai/sdk";
import { describe, expect, it } from "bun:test";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { pathToFileURL } from "node:url";

type NeverStopStateFile = {
	sessions: Record<
		string,
		{ prompt: string; updatedAt: number; lastSentAt: number; lastActivityAt: number }
	>;
};

type LiveRuntime = {
	workspaceDir: string;
	client: OpencodeClient;
};

const LIVE_TEST_TIMEOUT_MS = 25_000;
const FULL_LIVE_TEST_TIMEOUT_MS = 35_000;
const WAIT_TIMEOUT_MS = 8_000;
const WAIT_INTERVAL_MS = 50;
const FULL_WAIT_TIMEOUT_MS = 15_000;

const hasOpencodeCli = (() => {
	try {
		const result = spawnSync("opencode", ["--version"], { stdio: "ignore" });
		return result.status === 0;
	} catch {
		return false;
	}
})();

const runFullLive = process.env.NEVER_STOP_LIVE_FULL === "1";
const liveIt = hasOpencodeCli ? it : it.skip;
const fullLiveIt = hasOpencodeCli && runFullLive ? it : it.skip;

const pluginPath = path.resolve(import.meta.dir, "..", "never-stop.ts");
const pluginUri = pathToFileURL(pluginPath).href;

const testCommandConfig = {
	"never-stop": {
		description: "Set never-stop prompt for this session",
		template: "<user-request>\n$ARGUMENTS\n</user-request>",
	},
	"never-stop-clear": {
		description: "Clear never-stop prompt for this session",
		template: "<user-request>\n$ARGUMENTS\n</user-request>",
	},
};

let nextPort = 4269;

function allocatePort(): number {
	nextPort += 1;
	return nextPort;
}

function restoreEnv(key: string, value: string | undefined): void {
	if (value === undefined) {
		Reflect.deleteProperty(process.env, key);
		return;
	}
	process.env[key] = value;
}

function getStatePath(workspaceDir: string): string {
	return path.join(workspaceDir, ".opencode", "state", "never-stop.json");
}

function readState(workspaceDir: string): NeverStopStateFile {
	const statePath = getStatePath(workspaceDir);
	if (!fs.existsSync(statePath)) return { sessions: {} };
	return JSON.parse(fs.readFileSync(statePath, "utf-8")) as NeverStopStateFile;
}

async function waitFor(condition: () => boolean, timeoutMs = WAIT_TIMEOUT_MS) {
	const startedAt = Date.now();
	while (Date.now() - startedAt < timeoutMs) {
		if (condition()) return;
		await Bun.sleep(WAIT_INTERVAL_MS);
	}
	throw new Error(`Condition not met within ${timeoutMs}ms`);
}

async function waitForEvent(
	client: OpencodeClient,
	workspaceDir: string,
	predicate: (event: OpencodeEvent) => boolean,
	timeoutMs = FULL_WAIT_TIMEOUT_MS,
): Promise<void> {
	const controller = new AbortController();
	const timeoutID = setTimeout(() => controller.abort(), timeoutMs);

	try {
		const subscription = await client.event.subscribe({
			query: { directory: workspaceDir },
			signal: controller.signal,
		});

		for await (const event of subscription.stream) {
			if (predicate(event)) {
				return;
			}
		}
	} catch (error) {
		if (controller.signal.aborted) {
			throw new Error(`Event condition not met within ${timeoutMs}ms`);
		}
		throw error;
	} finally {
		clearTimeout(timeoutID);
		controller.abort();
	}

	throw new Error(`Event condition not met within ${timeoutMs}ms`);
}

async function createSession(client: OpencodeClient, workspaceDir: string): Promise<string> {
	const created = await client.session.create({
		query: { directory: workspaceDir },
		throwOnError: true,
	});
	return created.data.id;
}

async function withLiveRuntime(run: (runtime: LiveRuntime) => Promise<void>): Promise<void> {
	const workspaceDir = fs.mkdtempSync(path.join(os.tmpdir(), "never-stop-live-"));
	const fakeHome = fs.mkdtempSync(path.join(os.tmpdir(), "never-stop-home-"));
	const previousHome = process.env.HOME;
	const previousIdleDelay = process.env.NEVER_STOP_IDLE_DELAY_MS;
	const previousCooldown = process.env.NEVER_STOP_SEND_COOLDOWN_MS;
	const previousGrace = process.env.NEVER_STOP_INTERRUPT_GRACE_MS;
	const previousReinforcePeriod = process.env.NEVER_STOP_REINFORCE_PERIOD_MS;
	const previousReinforceTick = process.env.NEVER_STOP_REINFORCE_TICK_MS;
	let runtime: Awaited<ReturnType<typeof createOpencode>> | null = null;

	process.env.HOME = fakeHome;
	process.env.NEVER_STOP_IDLE_DELAY_MS = "10";
	process.env.NEVER_STOP_SEND_COOLDOWN_MS = "0";
	process.env.NEVER_STOP_INTERRUPT_GRACE_MS = "0";
	process.env.NEVER_STOP_REINFORCE_PERIOD_MS = "0";
	process.env.NEVER_STOP_REINFORCE_TICK_MS = "200";

	try {
		runtime = await createOpencode({
			port: allocatePort(),
			timeout: 12_000,
			config: {
				plugin: [pluginUri],
				command: testCommandConfig,
			},
		});

		await run({ workspaceDir, client: runtime.client });
	} finally {
		runtime?.server.close();
		fs.rmSync(workspaceDir, { recursive: true, force: true });
		fs.rmSync(fakeHome, { recursive: true, force: true });
		restoreEnv("HOME", previousHome);
		restoreEnv("NEVER_STOP_IDLE_DELAY_MS", previousIdleDelay);
		restoreEnv("NEVER_STOP_SEND_COOLDOWN_MS", previousCooldown);
		restoreEnv("NEVER_STOP_INTERRUPT_GRACE_MS", previousGrace);
		restoreEnv("NEVER_STOP_REINFORCE_PERIOD_MS", previousReinforcePeriod);
		restoreEnv("NEVER_STOP_REINFORCE_TICK_MS", previousReinforceTick);
	}
}

describe("never-stop live runtime", () => {
	liveIt(
		"wires command execution into persisted never-stop state",
		async () => {
			await withLiveRuntime(async ({ client, workspaceDir }) => {
				const commandList = await client.command.list({
					query: { directory: workspaceDir },
					throwOnError: true,
				});

				expect(commandList.data.some((command) => command.name === "never-stop")).toBe(
					true,
				);

				const sessionID = await createSession(client, workspaceDir);
				const targetPrompt = "Continue without stopping";

				await client.session.command({
					path: { id: sessionID },
					query: { directory: workspaceDir },
					body: {
						command: "never-stop",
						arguments: targetPrompt,
					},
					throwOnError: true,
				});

				await waitFor(() => {
					const state = readState(workspaceDir);
					return state.sessions[sessionID]?.prompt === targetPrompt;
				});
				expect(readState(workspaceDir).sessions[sessionID]?.prompt).toBe(targetPrompt);

				await client.session.delete({
					path: { id: sessionID },
					query: { directory: workspaceDir },
					throwOnError: true,
				});

				await waitFor(() => {
					const state = readState(workspaceDir);
					return state.sessions[sessionID] === undefined;
				});
				expect(readState(workspaceDir).sessions[sessionID]).toBeUndefined();
			});
		},
		LIVE_TEST_TIMEOUT_MS,
	);

	fullLiveIt(
		"auto-sends continuation after session becomes idle (opt-in)",
		async () => {
			await withLiveRuntime(async ({ client, workspaceDir }) => {
				const sessionID = await createSession(client, workspaceDir);
				const targetPrompt = "Continue without stopping";

				const idleObserved = waitForEvent(
					client,
					workspaceDir,
					(event) =>
						event.type === "session.idle" && event.properties.sessionID === sessionID,
				);

				await client.session.command({
					path: { id: sessionID },
					query: { directory: workspaceDir },
					body: {
						command: "never-stop",
						arguments: targetPrompt,
					},
					throwOnError: true,
				});

				await waitFor(() => {
					const state = readState(workspaceDir);
					return state.sessions[sessionID]?.prompt === targetPrompt;
				});

				await idleObserved;

				await waitFor(() => {
					const state = readState(workspaceDir);
					const entry = state.sessions[sessionID];
					return Boolean(entry && entry.lastSentAt > 0);
				}, FULL_WAIT_TIMEOUT_MS);

				const state = readState(workspaceDir);
				expect(state.sessions[sessionID]?.lastSentAt ?? 0).toBeGreaterThan(0);
			});
		},
		FULL_LIVE_TEST_TIMEOUT_MS,
	);
});

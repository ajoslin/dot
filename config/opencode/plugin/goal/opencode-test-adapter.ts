import {
	createOpencode,
	type Event as OpencodeEvent,
	type OpencodeClient,
} from "@opencode-ai/sdk";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { pathToFileURL } from "node:url";

export type GoalLiveRuntime = {
	workspaceDir: string;
	client: OpencodeClient;
};

export type StartedGoalRuntime = Awaited<ReturnType<typeof createOpencode>>;

const pluginPath = path.resolve(import.meta.dir, "..", "goal.ts");
const pluginUri = pathToFileURL(pluginPath).href;

const testCommandConfig = {
	goal: {
		description: "Manage the active goal for this session",
		template: "<user-request>\n$ARGUMENTS\n</user-request>",
	},
};

let nextPort = 4369;

export function hasOpencodeCli(): boolean {
	try {
		const result = spawnSync("opencode", ["--version"], { stdio: "ignore" });
		return result.status === 0;
	} catch {
		return false;
	}
}

export function allocateGoalRuntimePort(): number {
	nextPort += 1;
	return nextPort;
}

export async function startGoalRuntime(): Promise<StartedGoalRuntime> {
	return createOpencode({
		port: allocateGoalRuntimePort(),
		timeout: 12_000,
		config: {
			plugin: [pluginUri],
			command: testCommandConfig,
		},
	});
}

export async function withGoalLiveRuntime(
	run: (runtime: GoalLiveRuntime) => Promise<void>,
): Promise<void> {
	const workspaceDir = fs.mkdtempSync(path.join(os.tmpdir(), "goal-live-"));
	const fakeHome = fs.mkdtempSync(path.join(os.tmpdir(), "goal-home-"));
	const previousHome = process.env.HOME;
	let runtime: StartedGoalRuntime | null = null;

	process.env.HOME = fakeHome;

	try {
		runtime = await startGoalRuntime();
		await run({ workspaceDir, client: runtime.client });
	} finally {
		runtime?.server.close();
		fs.rmSync(workspaceDir, { recursive: true, force: true });
		fs.rmSync(fakeHome, { recursive: true, force: true });
		restoreHome(previousHome);
	}
}

export async function createGoalSession(
	client: OpencodeClient,
	workspaceDir: string,
): Promise<string> {
	const created = await client.session.create({
		query: { directory: workspaceDir },
		throwOnError: true,
	});
	return created.data.id;
}

export async function runGoalCommand(
	client: OpencodeClient,
	workspaceDir: string,
	sessionID: string,
	args: string,
): Promise<void> {
	await client.session.command({
		path: { id: sessionID },
		query: { directory: workspaceDir },
		body: {
			command: "goal",
			arguments: args,
		},
		throwOnError: true,
	});
}

export async function waitForGoalEvent(
	client: OpencodeClient,
	workspaceDir: string,
	predicate: (event: OpencodeEvent) => boolean,
	timeoutMs = 15_000,
): Promise<OpencodeEvent> {
	const controller = new AbortController();
	const timeoutID = setTimeout(() => controller.abort(), timeoutMs);

	try {
		const subscription = await client.event.subscribe({
			query: { directory: workspaceDir },
			signal: controller.signal,
		});

		for await (const event of subscription.stream) {
			if (predicate(event)) return event;
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

export function restoreHome(previousHome: string | undefined): void {
	if (previousHome === undefined) {
		Reflect.deleteProperty(process.env, "HOME");
		return;
	}
	process.env.HOME = previousHome;
}

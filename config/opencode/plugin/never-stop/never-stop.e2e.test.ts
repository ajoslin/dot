import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import NeverStopPlugin from "../never-stop.ts";

type PromptRequest = {
	path: { id: string };
	body: { parts: Array<{ type: "text"; text: string }> };
	query: { directory: string };
};

type ToastRequest = {
	body: { title: string; message: string; variant: string };
};

type NeverStopStateFile = {
	sessions: Record<
		string,
		{ prompt: string; updatedAt: number; lastSentAt: number; lastActivityAt: number }
	>;
};

const ENV_KEYS = [
	"NEVER_STOP_IDLE_DELAY_MS",
	"NEVER_STOP_SEND_COOLDOWN_MS",
	"NEVER_STOP_INTERRUPT_GRACE_MS",
	"NEVER_STOP_REINFORCE_PERIOD_MS",
	"NEVER_STOP_REINFORCE_TICK_MS",
	"NEVER_STOP_FAILURE_BACKOFF_BASE_MS",
	"NEVER_STOP_FAILURE_RESET_WINDOW_MS",
	"NEVER_STOP_MAX_CONSECUTIVE_FAILURES",
] as const;

let directory = "";
let envBackup: Record<string, string | undefined> = {};

function getStatePath(rootDirectory: string): string {
	return path.join(rootDirectory, ".opencode", "state", "never-stop.json");
}

function readState(rootDirectory: string): NeverStopStateFile {
	const statePath = getStatePath(rootDirectory);
	if (!fs.existsSync(statePath)) return { sessions: {} };
	return JSON.parse(fs.readFileSync(statePath, "utf-8")) as NeverStopStateFile;
}

	function createMockClient(options?: { failPrompt?: boolean }) {
	const prompts: PromptRequest[] = [];
	const toasts: ToastRequest[] = [];

	const client = {
		tui: {
			async showToast(input: ToastRequest) {
				toasts.push(input);
				return { ok: true };
			},
		},
		session: {
			async prompt(input: PromptRequest) {
				if (options?.failPrompt) {
					throw new Error("prompt failed");
				}
				prompts.push(input);
				return { ok: true };
			},
		},
	};

	return { client, prompts, toasts };
}

describe("never-stop plugin e2e", () => {
	beforeEach(() => {
		directory = fs.mkdtempSync(path.join(os.tmpdir(), "never-stop-e2e-"));
		envBackup = {};
		for (const key of ENV_KEYS) {
			envBackup[key] = process.env[key];
		}

		process.env.NEVER_STOP_IDLE_DELAY_MS = "10";
		process.env.NEVER_STOP_SEND_COOLDOWN_MS = "0";
		process.env.NEVER_STOP_INTERRUPT_GRACE_MS = "0";
		process.env.NEVER_STOP_REINFORCE_PERIOD_MS = "300000";
		process.env.NEVER_STOP_REINFORCE_TICK_MS = "1000";
	});

	afterEach(() => {
		for (const key of ENV_KEYS) {
			const previous = envBackup[key];
			if (previous === undefined) {
				delete process.env[key];
				continue;
			}
			process.env[key] = previous;
		}

		fs.rmSync(directory, { recursive: true, force: true });
	});

	it("parses command.executed name+arguments and persists state", async () => {
		const { client } = createMockClient();
		const plugin = await NeverStopPlugin({ directory, client });
		const sessionID = "session-a";

		await plugin.event({
			event: {
				type: "command.executed",
				properties: {
					name: "never-stop",
					sessionID,
					arguments: "Continue until done",
					messageID: "m1",
				},
			},
		});

		const state = readState(directory);
		expect(state.sessions[sessionID]?.prompt).toBe("Continue until done");

		await plugin.event({
			event: {
				type: "session.deleted",
				properties: { info: { id: sessionID } },
			},
		});
	});

	it("sends continuation immediately on idle with short delay", async () => {
		const { client, prompts } = createMockClient();
		const plugin = await NeverStopPlugin({ directory, client });
		const sessionID = "session-b";
		const prompt = "Keep shipping";

		await plugin.event({
			event: {
				type: "command.executed",
				properties: {
					name: "never-stop",
					sessionID,
					arguments: prompt,
					messageID: "m2",
				},
			},
		});

		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		await Bun.sleep(30);

		expect(prompts.length).toBe(1);
		expect(prompts[0]?.body.parts[0]?.text).toBe(prompt);

		await plugin.event({
			event: {
				type: "session.deleted",
				properties: { info: { id: sessionID } },
			},
		});
	});

	it("sends on each idle transition even when cooldown is active", async () => {
		process.env.NEVER_STOP_SEND_COOLDOWN_MS = "60000";

		const { client, prompts } = createMockClient();
		const plugin = await NeverStopPlugin({ directory, client });
		const sessionID = "session-idle-repeat";
		const prompt = "Keep going";

		await plugin.event({
			event: {
				type: "command.executed",
				properties: {
					name: "never-stop",
					sessionID,
					arguments: prompt,
					messageID: "m-repeat",
				},
			},
		});

		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		await Bun.sleep(30);

		expect(prompts.length).toBe(1);

		await plugin.event({
			event: {
				type: "message.updated",
				properties: {
					sessionID,
					messageID: "m-repeat",
				},
			},
		});

		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		await Bun.sleep(30);

		expect(prompts.length).toBe(2);
		expect(prompts[1]?.body.parts[0]?.text).toBe(prompt);

		await plugin.event({
			event: {
				type: "session.deleted",
				properties: { info: { id: sessionID } },
			},
		});
	});

	it("disables never-stop after three session errors within five minutes", async () => {
		process.env.NEVER_STOP_FAILURE_RESET_WINDOW_MS = "300000";
		process.env.NEVER_STOP_MAX_CONSECUTIVE_FAILURES = "3";

		const { client, prompts, toasts } = createMockClient();
		const plugin = await NeverStopPlugin({ directory, client });
		const sessionID = "session-error-stop";

		await plugin.event({
			event: {
				type: "command.executed",
				properties: {
					name: "never-stop",
					sessionID,
					arguments: "Recover if possible",
					messageID: "m-errors",
				},
			},
		});

		for (let index = 0; index < 3; index++) {
			await plugin.event({
				event: {
					type: "session.error",
					properties: {
						sessionID,
						error: { name: `ModelError${index}` },
					},
				},
			});
		}

		expect(readState(directory).sessions[sessionID]).toBeUndefined();
		expect(toasts.at(-1)?.body.message).toContain("disabled after 3 errors within 5m");

		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		await Bun.sleep(30);
		expect(prompts.length).toBe(0);
	});

	it("disables never-stop after three failed auto-sends within five minutes", async () => {
		process.env.NEVER_STOP_FAILURE_BACKOFF_BASE_MS = "0";
		process.env.NEVER_STOP_FAILURE_RESET_WINDOW_MS = "300000";
		process.env.NEVER_STOP_MAX_CONSECUTIVE_FAILURES = "3";

		const { client, toasts } = createMockClient({ failPrompt: true });
		const plugin = await NeverStopPlugin({ directory, client });
		const sessionID = "session-prompt-fail-stop";

		await plugin.event({
			event: {
				type: "command.executed",
				properties: {
					name: "never-stop",
					sessionID,
					arguments: "Try again",
					messageID: "m-failures",
				},
			},
		});

		for (let index = 0; index < 3; index++) {
			await plugin.event({
				event: { type: "session.idle", properties: { sessionID } },
			});
			await Bun.sleep(30);
			await plugin.event({
				event: {
					type: "message.updated",
					properties: {
						sessionID,
						messageID: `m-failures-${index}`,
					},
				},
			});
		}

		expect(readState(directory).sessions[sessionID]).toBeUndefined();
		expect(toasts.at(-1)?.body.message).toContain("disabled after 3 errors within 5m");
	});

	it("cancels pending idle send when activity arrives via part.sessionID", async () => {
		const { client, prompts } = createMockClient();
		const plugin = await NeverStopPlugin({ directory, client });
		const sessionID = "session-c";

		await plugin.event({
			event: {
				type: "command.executed",
				properties: {
					name: "never-stop",
					sessionID,
					arguments: "Continue",
					messageID: "m3",
				},
			},
		});

		await plugin.event({ event: { type: "session.idle", properties: { sessionID } } });
		await plugin.event({
			event: {
				type: "message.part.updated",
				properties: {
					part: {
						sessionID,
						id: "part-1",
						messageID: "m3",
						type: "text",
						text: "still working",
					},
				},
			},
		});

		await Bun.sleep(30);
		expect(prompts.length).toBe(0);

		await plugin.event({
			event: {
				type: "session.deleted",
				properties: { info: { id: sessionID } },
			},
		});
	});
});

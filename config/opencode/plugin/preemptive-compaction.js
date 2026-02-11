import { tool } from "@opencode-ai/plugin";
import * as fs from "node:fs";
import * as path from "node:path";

const THRESHOLD = 0.8;
const COOLDOWN_MS = 60_000;
const CONTINUE_DELAY_MS = 500;

const CONTEXT_LIMIT_DEFAULT = 200_000;
const MODEL_CONTEXT_LIMITS = [
  {
    pattern: /claude-(opus|sonnet|haiku)/i,
    limit:
      process.env.ANTHROPIC_1M_CONTEXT === "true" ||
      process.env.VERTEX_ANTHROPIC_1M_CONTEXT === "true"
        ? 1_000_000
        : 200_000,
  },
  { pattern: /gpt-?5(\.|-|$)/i, limit: 400_000 },
  { pattern: /kimi.*k2\.5|kimi.*2\.5|k2\.5/i, limit: 200_000 },
];

const STATE_DIR = ".opencode/state";
const CONFIG_FILE = "preemptive-compaction.json";

const lastCompactionTime = new Map();
const inProgress = new Set();

function getConfigPath(directory) {
  return path.join(directory, STATE_DIR, CONFIG_FILE);
}

function ensureStateDir(directory) {
  const stateDir = path.join(directory, STATE_DIR);
  if (!fs.existsSync(stateDir)) {
    fs.mkdirSync(stateDir, { recursive: true });
  }
}

function readConfig(directory) {
  const configPath = getConfigPath(directory);
  if (!fs.existsSync(configPath)) return { enabled: true };
  try {
    const content = fs.readFileSync(configPath, "utf-8");
    const parsed = JSON.parse(content);
    return { enabled: parsed?.enabled !== false };
  } catch {
    return { enabled: true };
  }
}

function writeConfig(directory, config) {
  ensureStateDir(directory);
  const configPath = getConfigPath(directory);
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

function getContextLimit(modelID) {
  const envLimit = Number.parseInt(process.env.PCOMPACT_CONTEXT_LIMIT ?? "", 10);
  if (Number.isFinite(envLimit) && envLimit > 0) return envLimit;

  const matched = MODEL_CONTEXT_LIMITS.find((entry) => entry.pattern.test(modelID));
  return matched?.limit ?? CONTEXT_LIMIT_DEFAULT;
}

function calculateUsage(tokens) {
  return tokens.input + tokens.cache.read + tokens.output;
}

async function showToast(client, message, variant) {
  try {
    await client.tui.showToast({ body: { message, variant } });
  } catch {
    // TUI may not be available
  }
}

async function handleMessageUpdated(event, client, directory) {
  if (event.type !== "message.updated") return;

  const config = readConfig(directory);
  if (!config.enabled) return;

  const info = event.properties?.info;
  if (!info) return;
  if (info.role !== "assistant") return;
  if (!info.finish || !info.tokens || !info.modelID || !info.providerID) return;
  if (info.summary) return;

  const sessionID = info.sessionID;
  if (inProgress.has(sessionID)) return;

  const lastTime = lastCompactionTime.get(sessionID) ?? 0;
  if (Date.now() - lastTime < COOLDOWN_MS) return;

  const used = calculateUsage(info.tokens);
  const limit = getContextLimit(info.modelID);
  const ratio = used / limit;
  if (ratio < THRESHOLD) return;

  inProgress.add(sessionID);
  lastCompactionTime.set(sessionID, Date.now());

  const pct = (ratio * 100).toFixed(0);
  await showToast(client, `Context at ${pct}% - compacting...`, "warning");

  try {
    await client.session.summarize({
      path: { id: sessionID },
      body: {
        providerID: info.providerID,
        modelID: info.modelID,
      },
      query: { directory },
    });

    await showToast(client, "Compaction complete", "success");

    setTimeout(async () => {
      try {
        await client.session.prompt({
          path: { id: sessionID },
          body: { parts: [{ type: "text", text: "Continue" }] },
          query: { directory },
        });
      } catch {
        // Session may be gone
      }
    }, CONTINUE_DELAY_MS);
  } catch (error) {
    await showToast(
      client,
      `Compaction failed: ${error instanceof Error ? error.message : "Unknown"}`,
      "error",
    );
  } finally {
    inProgress.delete(sessionID);
  }
}

function handleSessionDeleted(event) {
  if (event.type !== "session.deleted") return;

  const info = event.properties?.info;
  if (info?.id) {
    lastCompactionTime.delete(info.id);
    inProgress.delete(info.id);
  }
}

function createCompactToggle(directory) {
  return tool({
    description: "Toggle preemptive compaction on/off. Returns new state.",
    args: {
      enabled: tool.schema
        .boolean()
        .optional()
        .describe("Set enabled state (toggles if omitted)"),
    },
    async execute(args) {
      const config = readConfig(directory);
      const newEnabled = args.enabled ?? !config.enabled;
      writeConfig(directory, { enabled: newEnabled });
      return `[compact] preemptive compaction ${newEnabled ? "enabled" : "disabled"}`;
    },
  });
}

function createCompactStatus(directory) {
  return tool({
    description: "Check preemptive compaction status.",
    args: {},
    async execute() {
      const config = readConfig(directory);
      const activeSessions = inProgress.size;
      const threshold = `${(THRESHOLD * 100).toFixed(0)}%`;
      const limit = `auto (${CONTEXT_LIMIT_DEFAULT.toLocaleString()} default)`;

      const lines = [
        `[compact] ${config.enabled ? "enabled" : "disabled"}`,
        `  threshold: ${threshold}`,
        `  context limit: ${limit} tokens`,
        `  cooldown: ${COOLDOWN_MS / 1000}s`,
        `  active compactions: ${activeSessions}`,
      ];

      return lines.join("\n");
    },
  });
}

export const PreemptiveCompactionPlugin = async (ctx) => {
  return {
    event: async ({ event }) => {
      await handleMessageUpdated(event, ctx.client, ctx.directory);
      handleSessionDeleted(event);
    },
    tool: {
      pcompact_toggle: createCompactToggle(ctx.directory),
      pcompact_status: createCompactStatus(ctx.directory),
    },
  };
};

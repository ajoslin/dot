import { execFileSync } from "node:child_process";

const AUTO_CONTINUE_DELAY_MS = 2000;
const AUTO_CONTINUE_COOLDOWN_MS = 10000;
const ABORT_GRACE_MS = 3000;
const OVERSEER_SESSION_TTL_MS = 30 * 60 * 1000;

const ORCHESTRATE_CMD = "/overseer_orchestrate";
const TASK_ID_REGEX = /(task_[A-Za-z0-9]+)/;

function getSessionId(event) {
  return event?.properties?.sessionID;
}

function getSessionIdFromMessage(event) {
  return event?.properties?.info?.sessionID;
}

function isSessionIdleEvent(event) {
  if (event?.type === "session.idle") return true;
  return (
    event?.type === "session.status" &&
    event?.properties?.status?.type === "idle" &&
    typeof event?.properties?.sessionID === "string"
  );
}

function isActivityEvent(event) {
  return (
    event?.type === "message.updated" ||
    event?.type === "message.part.updated" ||
    event?.type === "command.executed"
  );
}

function collectStrings(value, out = []) {
  if (typeof value === "string") {
    out.push(value);
    return out;
  }
  if (!value || typeof value !== "object") {
    return out;
  }
  if (Array.isArray(value)) {
    for (const item of value) collectStrings(item, out);
    return out;
  }
  for (const v of Object.values(value)) collectStrings(v, out);
  return out;
}

function normalizeResumeCommand(raw) {
  if (typeof raw !== "string") return null;
  const line = raw.trim();
  if (!line.startsWith(ORCHESTRATE_CMD)) return null;
  if (line === ORCHESTRATE_CMD) return null;
  return line;
}

function extractResumeCommandFromText(text) {
  if (typeof text !== "string") return null;
  const match = text.match(/\/overseer_orchestrate[^\n\r]*/);
  return normalizeResumeCommand(match?.[0] ?? null);
}

function extractResumeCommandFromEvent(event) {
  const direct = normalizeResumeCommand(event?.properties?.command);
  if (direct) return direct;

  const strings = collectStrings(event?.properties);
  for (const text of strings) {
    const cmd = extractResumeCommandFromText(text);
    if (cmd) return cmd;
  }
  return null;
}

function readGitHead(directory) {
  try {
    return execFileSync("git", ["rev-parse", "HEAD"], {
      cwd: directory,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return null;
  }
}

function hasDirtyWorkingTree(directory) {
  try {
    const out = execFileSync("git", ["status", "--porcelain"], {
      cwd: directory,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    return out.trim().length > 0;
  } catch {
    return false;
  }
}

function parentFromCommand(command) {
  if (!command) return null;
  const id = command.match(TASK_ID_REGEX);
  return id ? id[1] : null;
}

async function safeShowToast(client, message, variant = "info") {
  try {
    await client.tui.showToast({
      body: {
        title: "Overseer Orchestrate",
        message,
        variant,
        duration: 1500,
      },
    });
  } catch {
    // TUI may be unavailable in some contexts.
  }
}

export const OverseerOrchestrateAutoContinuePlugin = async (ctx) => {
  const countdownTimers = new Map();
  const lastInjectedAt = new Map();
  const inFlightTaskCalls = new Map();
  const abortDetectedAt = new Map();
  const taskCallStartCommit = new Map();
  const commitBlockedSessions = new Set();
  const lastCommitReminderAt = new Map();
  const activeResumeCommand = new Map();
  const lastOverseerActivityAt = new Map();

  function callKey(sessionID, callID) {
    return `${sessionID}:${callID}`;
  }

  function clearSessionState(sessionID) {
    const timer = countdownTimers.get(sessionID);
    if (timer) clearTimeout(timer);
    countdownTimers.delete(sessionID);
    lastInjectedAt.delete(sessionID);
    inFlightTaskCalls.delete(sessionID);
    abortDetectedAt.delete(sessionID);
    commitBlockedSessions.delete(sessionID);
    lastCommitReminderAt.delete(sessionID);
    activeResumeCommand.delete(sessionID);
    lastOverseerActivityAt.delete(sessionID);
    for (const key of taskCallStartCommit.keys()) {
      if (key.startsWith(`${sessionID}:`)) taskCallStartCommit.delete(key);
    }
  }

  function cancelCountdown(sessionID) {
    const timer = countdownTimers.get(sessionID);
    if (!timer) return;
    clearTimeout(timer);
    countdownTimers.delete(sessionID);
  }

  function getTaskCallCount(sessionID) {
    return inFlightTaskCalls.get(sessionID) ?? 0;
  }

  function incrementTaskCallCount(sessionID) {
    inFlightTaskCalls.set(sessionID, getTaskCallCount(sessionID) + 1);
  }

  function decrementTaskCallCount(sessionID) {
    const next = Math.max(0, getTaskCallCount(sessionID) - 1);
    if (next === 0) {
      inFlightTaskCalls.delete(sessionID);
      return;
    }
    inFlightTaskCalls.set(sessionID, next);
  }

  function updateOverseerSession(sessionID, command) {
    if (!sessionID || !command) return;
    activeResumeCommand.set(sessionID, command);
    lastOverseerActivityAt.set(sessionID, Date.now());
  }

  function getActiveResumeCommand(sessionID) {
    const cmd = activeResumeCommand.get(sessionID);
    if (!cmd) return null;
    const last = lastOverseerActivityAt.get(sessionID) ?? 0;
    if (Date.now() - last > OVERSEER_SESSION_TTL_MS) {
      activeResumeCommand.delete(sessionID);
      lastOverseerActivityAt.delete(sessionID);
      return null;
    }
    return cmd;
  }

  async function maybeInjectContinuation(sessionID) {
    if (!sessionID) return;
    if (getTaskCallCount(sessionID) > 0) return;

    const abortAt = abortDetectedAt.get(sessionID) ?? 0;
    if (abortAt > 0 && Date.now() - abortAt < ABORT_GRACE_MS) return;

    const last = lastInjectedAt.get(sessionID) ?? 0;
    if (Date.now() - last < AUTO_CONTINUE_COOLDOWN_MS) return;

    const resumeCommand = getActiveResumeCommand(sessionID);
    if (!resumeCommand) return;

    if (commitBlockedSessions.has(sessionID) && hasDirtyWorkingTree(ctx.directory)) {
      const lastReminder = lastCommitReminderAt.get(sessionID) ?? 0;
      if (Date.now() - lastReminder >= AUTO_CONTINUE_COOLDOWN_MS) {
        const parent = parentFromCommand(resumeCommand);
        const statusLine = parent ? `Parent: ${parent}` : "Parent: (unknown from command)";
        try {
          await ctx.client.session.prompt({
            path: { id: sessionID },
            body: {
              parts: [
                {
                  type: "text",
                  text: [
                    "[overseer-orchestrate commit checkpoint]",
                    "Auto-resume paused: working tree has uncommitted changes.",
                    "Create a commit now, then continue orchestration.",
                    statusLine,
                    `Resume command: ${resumeCommand}`,
                  ].join("\n"),
                },
              ],
            },
            query: { directory: ctx.directory },
          });
          lastCommitReminderAt.set(sessionID, Date.now());
          await safeShowToast(ctx.client, "Commit required before auto-resume", "warning");
        } catch {
          // Ignore prompt failures; keep pause behavior.
        }
      }
      return;
    }

    commitBlockedSessions.delete(sessionID);

    try {
      await ctx.client.session.prompt({
        path: { id: sessionID },
        body: { parts: [{ type: "text", text: resumeCommand }] },
        query: { directory: ctx.directory },
      });
      lastInjectedAt.set(sessionID, Date.now());
      lastOverseerActivityAt.set(sessionID, Date.now());
      await safeShowToast(ctx.client, "Overseer auto-resume injected", "warning");
    } catch {
      // Session may be unavailable.
    }
  }

  function scheduleContinuation(sessionID) {
    if (!sessionID) return;
    if (getTaskCallCount(sessionID) > 0) return;
    cancelCountdown(sessionID);
    const timer = setTimeout(() => {
      countdownTimers.delete(sessionID);
      void maybeInjectContinuation(sessionID);
    }, AUTO_CONTINUE_DELAY_MS);
    countdownTimers.set(sessionID, timer);
  }

  return {
    event: async ({ event }) => {
      if (event?.type === "session.deleted") {
        const sessionID = event?.properties?.info?.id;
        if (sessionID) clearSessionState(sessionID);
        return event;
      }

      const sessionID =
        getSessionId(event) ?? getSessionIdFromMessage(event) ?? event?.properties?.sessionID;

      if (event?.type === "session.error") {
        const errorName = event?.properties?.error?.name;
        if (sessionID && (errorName === "MessageAbortedError" || errorName === "AbortError")) {
          abortDetectedAt.set(sessionID, Date.now());
          cancelCountdown(sessionID);
        }
      }

      const resumeCommand = extractResumeCommandFromEvent(event);
      if (sessionID && resumeCommand) {
        updateOverseerSession(sessionID, resumeCommand);
      }

      if (isActivityEvent(event) && sessionID) {
        cancelCountdown(sessionID);
      }

      if (!isSessionIdleEvent(event)) return event;
      scheduleContinuation(sessionID);
      return event;
    },

    "tool.execute.before": async (input) => {
      if (!input?.sessionID) return;
      cancelCountdown(input.sessionID);
      if (input.tool === "task") {
        incrementTaskCallCount(input.sessionID);
        if (input.callID && getActiveResumeCommand(input.sessionID)) {
          taskCallStartCommit.set(callKey(input.sessionID, input.callID), readGitHead(ctx.directory));
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (!input?.sessionID) return;
      cancelCountdown(input.sessionID);
      if (input.tool !== "task") return;

      decrementTaskCallCount(input.sessionID);

      const resumeCommand = getActiveResumeCommand(input.sessionID);
      if (!resumeCommand) return;

      const key = input.callID ? callKey(input.sessionID, input.callID) : null;
      const startCommit = key ? taskCallStartCommit.get(key) : null;
      if (key) taskCallStartCommit.delete(key);

      const endCommit = readGitHead(ctx.directory);
      const dirty = hasDirtyWorkingTree(ctx.directory);
      const commitAdvanced = Boolean(startCommit && endCommit && startCommit !== endCommit);

      if (commitAdvanced || !dirty) {
        commitBlockedSessions.delete(input.sessionID);
      }

      if (commitAdvanced) return;
      if (dirty) commitBlockedSessions.add(input.sessionID);

      const parent = parentFromCommand(resumeCommand);
      const reason = dirty ? "working tree has uncommitted changes" : "no new commit detected";
      const warning = [
        "[overseer-orchestrate commit checkpoint]",
        parent ? `Parent: ${parent}` : "Parent: (unknown from command)",
        `Status: FAILED (${reason})`,
        "Required next action: commit now, then continue orchestration.",
        `Resume command: ${resumeCommand}`,
      ].join("\n");

      output.output = `${output.output ?? ""}\n\n${warning}`.trim();
      await safeShowToast(ctx.client, "Commit checkpoint failed", "warning");
    },
  };
};

export default OverseerOrchestrateAutoContinuePlugin;

import { execFileSync } from "node:child_process";

const AUTO_CONTINUE_DELAY_MS = 2000;
const AUTO_CONTINUE_COOLDOWN_MS = 10000;
const ABORT_GRACE_MS = 3000;

const PARENT_TODO_ID_PREFIX = "ovr-parent-";
const RESUME_MARKER = "resume:/overseer_orchestrate";
const PARENT_ID_REGEX = /(task_[A-Za-z0-9]+)/;

function getSessionId(event) {
  return event?.properties?.sessionID;
}

function getSessionIdFromMessage(event) {
  return event?.properties?.info?.sessionID;
}

function isSessionIdleEvent(event) {
  if (event?.type === "session.idle") {
    return true;
  }
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

function parseParentId(todo) {
  if (!todo || typeof todo !== "object") {
    return null;
  }

  if (typeof todo.id === "string" && todo.id.startsWith(PARENT_TODO_ID_PREFIX)) {
    const idMatch = todo.id.slice(PARENT_TODO_ID_PREFIX.length).match(PARENT_ID_REGEX);
    if (idMatch) {
      return idMatch[1];
    }
  }

  if (typeof todo.content === "string" && todo.content.includes(RESUME_MARKER)) {
    const contentMatch = todo.content.match(/resume:\/overseer_orchestrate\s+(task_[A-Za-z0-9]+)/);
    if (contentMatch) {
      return contentMatch[1];
    }
  }

  return null;
}

function isOverseerOrchestrateParentTodo(todo) {
  if (!todo || todo.status !== "in_progress") {
    return false;
  }

  const hasParentIdPrefix =
    typeof todo.id === "string" && todo.id.startsWith(PARENT_TODO_ID_PREFIX);
  const hasResumeMarker =
    typeof todo.content === "string" && todo.content.includes(RESUME_MARKER);

  return hasParentIdPrefix || hasResumeMarker;
}

function getActiveOverseerParentId(todos) {
  if (!Array.isArray(todos)) {
    return null;
  }

  const parentTodo = todos.find(isOverseerOrchestrateParentTodo);
  if (!parentTodo) {
    return null;
  }

  return parseParentId(parentTodo);
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

  function callKey(sessionID, callID) {
    return `${sessionID}:${callID}`;
  }

  async function getSessionTodos(sessionID) {
    try {
      const response = await ctx.client.session.todo({ path: { id: sessionID } });
      return response?.data ?? response ?? [];
    } catch {
      return [];
    }
  }

  async function getActiveParentForSession(sessionID) {
    const todos = await getSessionTodos(sessionID);
    return getActiveOverseerParentId(todos);
  }

  function cancelCountdown(sessionID) {
    const existing = countdownTimers.get(sessionID);
    if (!existing) {
      return;
    }
    clearTimeout(existing);
    countdownTimers.delete(sessionID);
  }

  function clearSessionState(sessionID) {
    cancelCountdown(sessionID);
    lastInjectedAt.delete(sessionID);
    inFlightTaskCalls.delete(sessionID);
    abortDetectedAt.delete(sessionID);
    commitBlockedSessions.delete(sessionID);
    lastCommitReminderAt.delete(sessionID);

    for (const key of taskCallStartCommit.keys()) {
      if (key.startsWith(`${sessionID}:`)) {
        taskCallStartCommit.delete(key);
      }
    }
  }

  function getTaskCallCount(sessionID) {
    return inFlightTaskCalls.get(sessionID) ?? 0;
  }

  function incrementTaskCallCount(sessionID) {
    const next = getTaskCallCount(sessionID) + 1;
    inFlightTaskCalls.set(sessionID, next);
  }

  function decrementTaskCallCount(sessionID) {
    const next = Math.max(0, getTaskCallCount(sessionID) - 1);
    if (next === 0) {
      inFlightTaskCalls.delete(sessionID);
      return;
    }
    inFlightTaskCalls.set(sessionID, next);
  }

  async function maybeInjectContinuation(sessionID) {
    if (!sessionID) {
      return;
    }

    if (getTaskCallCount(sessionID) > 0) {
      return;
    }

    const abortAt = abortDetectedAt.get(sessionID) ?? 0;
    if (abortAt > 0 && Date.now() - abortAt < ABORT_GRACE_MS) {
      return;
    }

    const last = lastInjectedAt.get(sessionID) ?? 0;
    if (Date.now() - last < AUTO_CONTINUE_COOLDOWN_MS) {
      return;
    }

    const parentId = await getActiveParentForSession(sessionID);
    if (!parentId) {
      return;
    }

    if (commitBlockedSessions.has(sessionID) && hasDirtyWorkingTree(ctx.directory)) {
      const lastReminder = lastCommitReminderAt.get(sessionID) ?? 0;
      if (Date.now() - lastReminder >= AUTO_CONTINUE_COOLDOWN_MS) {
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
                    `Resume command: /overseer_orchestrate ${parentId}`,
                  ].join("\n"),
                },
              ],
            },
            query: { directory: ctx.directory },
          });
          lastCommitReminderAt.set(sessionID, Date.now());
          await safeShowToast(ctx.client, `Commit required before resume (${parentId})`, "warning");
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
        body: {
          parts: [{ type: "text", text: `/overseer_orchestrate ${parentId}` }],
        },
        query: { directory: ctx.directory },
      });
      lastInjectedAt.set(sessionID, Date.now());
      await safeShowToast(ctx.client, `Auto-resume injected for ${parentId}`, "warning");
    } catch {
      // Session may be gone or unavailable.
    }
  }

  function scheduleContinuation(sessionID) {
    if (!sessionID) {
      return;
    }

    if (getTaskCallCount(sessionID) > 0) {
      return;
    }

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
        if (sessionID) {
          clearSessionState(sessionID);
        }
        return;
      }

      if (event?.type === "session.error") {
        const sessionID = getSessionId(event);
        const errorName = event?.properties?.error?.name;
        if (
          sessionID &&
          (errorName === "MessageAbortedError" || errorName === "AbortError")
        ) {
          abortDetectedAt.set(sessionID, Date.now());
          cancelCountdown(sessionID);
        }
      }

      if (isActivityEvent(event)) {
        const sessionID =
          getSessionId(event) ?? getSessionIdFromMessage(event) ?? event?.properties?.sessionID;
        if (sessionID) {
          cancelCountdown(sessionID);
        }
      }

      if (!isSessionIdleEvent(event)) {
        return;
      }

      const sessionID = getSessionId(event);
      scheduleContinuation(sessionID);
    },

    "tool.execute.before": async (input) => {
      if (!input?.sessionID) {
        return;
      }
      cancelCountdown(input.sessionID);
      if (input.tool === "task") {
        incrementTaskCallCount(input.sessionID);
        const parentId = await getActiveParentForSession(input.sessionID);
        if (parentId && input.callID) {
          taskCallStartCommit.set(callKey(input.sessionID, input.callID), readGitHead(ctx.directory));
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (!input?.sessionID) {
        return;
      }
      cancelCountdown(input.sessionID);
      if (input.tool === "task") {
        decrementTaskCallCount(input.sessionID);

        const parentId = await getActiveParentForSession(input.sessionID);
        if (!parentId) {
          return;
        }

        const key = input.callID ? callKey(input.sessionID, input.callID) : null;
        const startCommit = key ? taskCallStartCommit.get(key) : null;
        if (key) {
          taskCallStartCommit.delete(key);
        }

        const endCommit = readGitHead(ctx.directory);
        const dirty = hasDirtyWorkingTree(ctx.directory);
        const commitAdvanced = Boolean(startCommit && endCommit && startCommit !== endCommit);

        if (commitAdvanced || !dirty) {
          commitBlockedSessions.delete(input.sessionID);
        }

        if (commitAdvanced) {
          return;
        }

        if (dirty) {
          commitBlockedSessions.add(input.sessionID);
        }

        const reason = dirty
          ? "working tree has uncommitted changes"
          : "no new commit detected";

        const warning = [
          "[overseer-orchestrate commit checkpoint]",
          `Parent: ${parentId}`,
          `Status: FAILED (${reason})`,
          "Required next action: commit now, then continue orchestration.",
          `Resume command: /overseer_orchestrate ${parentId}`,
        ].join("\n");

        output.output = `${output.output ?? ""}\n\n${warning}`.trim();
        await safeShowToast(ctx.client, `Commit checkpoint failed for ${parentId}`, "warning");
      }
    },
  };
};

export default OverseerOrchestrateAutoContinuePlugin;

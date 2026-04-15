/**
 * AbsolutelyContextHook — adapted from @parcadei's concept for OpenCode.
 *
 * When a user message contains "?", injects a reminder to ground answers
 * in primary sources (read files, look things up) instead of guessing.
 */
export const AbsolutelyContextPlugin = async ({ client }) => {
  return {
    "chat.message": async (input, output) => {
      const text = output.parts
        .filter((p) => p.type === "text")
        .map((p) => p.text)
        .join(" ");

      if (!text.includes("?")) return;

      output.parts.push({
        type: "text",
        text:
          "\n\n[CONTEXT HOOK] If this question is about the codebase, read the relevant " +
          "files before answering to back up your claims. If it's about a specific " +
          "library or tool, look it up using opensrc_execute, exa, or web search. " +
          "Any claim you make should be backed up by primary sources. " +
          "Do not answer from memory or assumptions.",
      });
    },
  };
};

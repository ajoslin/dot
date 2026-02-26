export const InterruptOnXPlugin = async ({ client }) => {
  return {
    "chat.message": async (input, output) => {
      if (output.parts.length !== 1) {
        return;
      }

      const [part] = output.parts;
      if (part.type !== "text" || part.text !== "x") {
        return;
      }

      output.parts = [];

      try {
        await client.tui.executeCommand({
          body: {
            command: "session.interrupt",
          },
        });
      } catch (error) {
        await client.app.log({
          body: {
            service: "interrupt-on-x",
            level: "debug",
            message: "session.interrupt failed; skipping abort fallback",
            extra: {
              sessionID: input.sessionID,
              error: error instanceof Error ? error.message : String(error),
            },
          },
        });
      }
    },
  };
};

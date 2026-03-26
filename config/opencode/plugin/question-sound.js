import { homedir } from "node:os";
import { join } from "node:path";

export const QuestionSoundPlugin = async ({ $, client }) => {
  if (process.env.OPENCODE_MUTE_SOUNDS === "1") return {};
  const soundPath = join(homedir(), ".config/opencode/sounds/18_monk_select.ogg");

  const isMainSession = async (sessionID) => {
    if (!sessionID) {
      return true;
    }

    try {
      const result = await client.session.get({ path: { id: sessionID } });
      const session = result.data ?? result;
      return !session.parentID;
    } catch {
      return true;
    }
  };

  return {
    event: async ({ event }) => {
      if (event.type !== "question.asked") {
        return event;
      }

      const sessionID = event.properties?.sessionID;
      if (await isMainSession(sessionID)) {
        await $`ffplay -nodisp -autoexit -loglevel quiet -af volume=0.7 ${soundPath}`;
      }
      return event;
    },
  };
};

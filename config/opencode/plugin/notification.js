import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

export const NotificationPlugin = async ({ $, client }) => {
  const soundsDir = join(homedir(), ".config/opencode/sounds");
  const soundPoolPath = join(soundsDir, "aoe2_click_pool.json");
  const stateDir = join(homedir(), ".config/opencode/state");
  const sessionMapPath = join(stateDir, "civ-session-map.json");
  const lastIndexPath = join(stateDir, "civ-last-index.json");
  let cachedSoundPool = null;
  let cachedSessionMap = null;
  let cachedLastIndex = null;

  const ensureStateDir = async () => {
    await mkdir(stateDir, { recursive: true });
  };

  const readJson = async (filePath, fallback) => {
    try {
      const contents = await readFile(filePath, "utf8");
      return JSON.parse(contents);
    } catch {
      return fallback;
    }
  };

  const loadSoundPool = async () => {
    if (!cachedSoundPool) {
      cachedSoundPool = await readJson(soundPoolPath, []);
    }
    return cachedSoundPool;
  };

  const loadSessionMap = async () => {
    if (!cachedSessionMap) {
      cachedSessionMap = await readJson(sessionMapPath, {});
    }
    return cachedSessionMap;
  };

  const loadLastIndex = async () => {
    if (cachedLastIndex === null) {
      const storedIndex = await readJson(lastIndexPath, -1);
      cachedLastIndex = Number.isInteger(storedIndex) ? storedIndex : -1;
    }
    return cachedLastIndex;
  };

  const saveSessionMap = async (sessionMap) => {
    await ensureStateDir();
    cachedSessionMap = sessionMap;
    await writeFile(sessionMapPath, JSON.stringify(sessionMap, null, 2));
  };

  const saveLastIndex = async (index) => {
    await ensureStateDir();
    cachedLastIndex = index;
    await writeFile(lastIndexPath, JSON.stringify(index));
  };

  const getSessionCiv = async (sessionID) => {
    if (!sessionID) {
      return null;
    }

    const soundPool = await loadSoundPool();
    if (!Array.isArray(soundPool) || soundPool.length === 0) {
      return null;
    }

    const sessionMap = await loadSessionMap();
    if (sessionMap[sessionID]) {
      return sessionMap[sessionID];
    }

    const lastIndex = await loadLastIndex();
    const nextIndex = (lastIndex + 1) % soundPool.length;
    const civEntry = soundPool[nextIndex];
    sessionMap[sessionID] = civEntry;
    await saveSessionMap(sessionMap);
    await saveLastIndex(nextIndex);
    return civEntry;
  };

  const playSessionSound = async (sessionID) => {
    const civEntry = await getSessionCiv(sessionID);
    if (!civEntry?.file) {
      return;
    }

    const soundPath = join(soundsDir, civEntry.file);
    await $`ffplay -nodisp -autoexit -loglevel quiet -af volume=0.7 ${soundPath}`;
  };

  // Check if a session is a main (non-subagent) session
  const isMainSession = async (sessionID) => {
    try {
      const result = await client.session.get({ path: { id: sessionID } });
      const session = result.data ?? result;
      return !session.parentID;
    } catch {
      // If we can't fetch the session, assume it's main to avoid missing notifications
      return true;
    }
  };

  return {
    event: async ({ event }) => {
      // Only notify for main session events, not background subagents
      if (event.type === "session.idle") {
        const sessionID = event.properties.sessionID;
        if (await isMainSession(sessionID)) {
          await playSessionSound(sessionID);
        }
      }

      // Permission prompt created
      if (event.type === "permission.asked") {
        const sessionID = event.properties?.sessionID;
        await playSessionSound(sessionID);
      }

      if (event.type === "session.deleted") {
        const sessionID = event.properties?.info?.id;
        if (sessionID) {
          const sessionMap = await loadSessionMap();
          if (sessionMap[sessionID]) {
            delete sessionMap[sessionID];
            await saveSessionMap(sessionMap);
          }
        }
      }
    },
  };
};

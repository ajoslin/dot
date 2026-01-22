#!/usr/bin/env bun
import { deflateSync } from "node:zlib";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const args = Bun.argv.slice(2);

const readFromStdin = async (): Promise<string> => {
  return new Response(Bun.stdin).text();
};

let code = "";

if (args[0] === "--file") {
  const filePath = args[1];
  if (!filePath) {
    console.error("Missing file path after --file");
    process.exit(1);
  }
  code = readFileSync(resolve(filePath), "utf8");
} else {
  code = await readFromStdin();
}

if (!code.trim()) {
  console.error("No Mermaid code provided via stdin or --file");
  process.exit(1);
}

const state = {
  code,
  mermaid: { theme: "default" },
  autoSync: true,
  updateDiagram: true,
};
const json = JSON.stringify(state);
const deflated = deflateSync(Buffer.from(json, "utf8"));
const b64 = deflated
  .toString("base64")
  .replace(/\+/g, "-")
  .replace(/\//g, "_")
  .replace(/=+$/g, "");

console.log(`https://mermaid.live/edit#pako:${b64}`);

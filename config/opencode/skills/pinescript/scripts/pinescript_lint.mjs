#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";

const SKILL_NAME = "pinescript";

const envFiles = [
  `.opencode/skill/${SKILL_NAME}/.env`,
  ".opencode/skill/.env",
  ".opencode/.env",
];

const parseEnvLine = (line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) {
    return null;
  }
  const eqIndex = trimmed.indexOf("=");
  if (eqIndex === -1) {
    return null;
  }
  const key = trimmed.slice(0, eqIndex).trim();
  let value = trimmed.slice(eqIndex + 1).trim();
  if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
    value = value.slice(1, -1);
  }
  return { key, value };
};

const loadEnvFile = (relativePath) => {
  const filePath = path.resolve(process.cwd(), relativePath);
  if (!fs.existsSync(filePath)) {
    return;
  }
  const contents = fs.readFileSync(filePath, "utf8");
  for (const line of contents.split(/\r?\n/)) {
    const parsed = parseEnvLine(line);
    if (!parsed) {
      continue;
    }
    if (process.env[parsed.key] === undefined) {
      process.env[parsed.key] = parsed.value;
    }
  }
};

for (const envFile of envFiles) {
  loadEnvFile(envFile);
}

const args = process.argv.slice(2);
if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
  console.log("Usage: node scripts/pinescript_lint.mjs <file-or-dir> [args]");
  console.log("Env: PINESCRIPT_LINT_CMD to override lint command.");
  process.exit(0);
}

const lintCommand = process.env.PINESCRIPT_LINT_CMD || "npx --yes pinescript-lint";
const fullCommand = `${lintCommand} ${args.join(" ")}`.trim();

if (process.env.PINESCRIPT_LINT_DRY_RUN === "1") {
  console.log(`DRY RUN: ${fullCommand}`);
  process.exit(0);
}

const child = spawn(fullCommand, {
  stdio: "inherit",
  shell: true,
});

child.on("exit", (code) => {
  process.exit(code ?? 1);
});

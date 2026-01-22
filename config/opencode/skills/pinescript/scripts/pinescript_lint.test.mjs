import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const scriptPath = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "pinescript_lint.mjs"
);

test("prints usage with no args", () => {
  const output = execFileSync("node", [scriptPath], {
    env: { ...process.env, PINESCRIPT_LINT_DRY_RUN: "1" },
    encoding: "utf8",
  });
  assert.match(output, /Usage:/);
});

test("dry run outputs full command", () => {
  const output = execFileSync("node", [scriptPath, "examples/sample.pine"], {
    env: {
      ...process.env,
      PINESCRIPT_LINT_DRY_RUN: "1",
      PINESCRIPT_LINT_CMD: "echo lint",
    },
    encoding: "utf8",
  });
  assert.match(output, /DRY RUN: echo lint examples\/sample\.pine/);
});

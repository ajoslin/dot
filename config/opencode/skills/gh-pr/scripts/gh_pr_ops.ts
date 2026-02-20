#!/usr/bin/env bun

import { execFileSync } from "node:child_process";

type Reactions = Record<string, number | null | undefined>;

type UnifiedComment = {
  kind: "issue_comment" | "review_comment" | "review_comment_reply";
  id: number;
  url: string | null;
  author: string | null;
  created_at: string | null;
  body: string;
  path: string | null;
  line: number | null;
  reactions: Reactions;
};

type QueueArgs = {
  repo: string;
  pr: number;
  json: boolean;
};

type MarkArgs = {
  repo: string;
  pr: number;
  ids: string;
  status: "pending" | "addressed";
};

function runGh(
  path: string,
  options?: {
    method?: "GET" | "POST";
    fields?: Record<string, string>;
    paginate?: boolean;
  },
) {
  const method = options?.method ?? "GET";
  const cmd = ["api", "--method", method, path];
  if (options?.paginate) {
    cmd.push("--paginate", "--slurp");
  }
  if (options?.fields) {
    for (const [key, value] of Object.entries(options.fields)) {
      cmd.push("-f", `${key}=${value}`);
    }
  }
  const out = execFileSync("gh", cmd, { encoding: "utf8" });
  const parsed = JSON.parse(out);
  if (!options?.paginate) {
    return parsed;
  }
  if (!Array.isArray(parsed)) {
    return parsed;
  }
  if (parsed.length === 0) {
    return [];
  }
  if (Array.isArray(parsed[0])) {
    return parsed.flat();
  }
  return parsed;
}

function normalizeIssueComment(item: any): UnifiedComment {
  return {
    kind: "issue_comment",
    id: item.id,
    url: item.html_url ?? null,
    author: item.user?.login ?? null,
    created_at: item.created_at ?? null,
    body: item.body ?? "",
    path: null,
    line: null,
    reactions: item.reactions ?? {},
  };
}

function normalizeReviewComment(item: any): UnifiedComment {
  return {
    kind: item.in_reply_to_id ? "review_comment_reply" : "review_comment",
    id: item.id,
    url: item.html_url ?? null,
    author: item.user?.login ?? null,
    created_at: item.created_at ?? null,
    body: item.body ?? "",
    path: item.path ?? null,
    line: item.line ?? null,
    reactions: item.reactions ?? {},
  };
}

function markerCount(reactions: Reactions | null | undefined, marker: string): number {
  if (!reactions) {
    return 0;
  }
  return Number(reactions[marker] ?? 0) || 0;
}

function reactionDefaults() {
  const addressed = process.env.ADDRESSED_REACTION || process.env.MARKER_REACTION || "+1";
  const pending = process.env.PENDING_REACTION || "eyes";
  return { addressed, pending };
}

export function isNewItem(
  item: Pick<UnifiedComment, "kind" | "body" | "reactions">,
  addressedMarker: string,
  pendingMarker: string,
  botPrefix: string,
): boolean {
  const body = item.body || "";
  if (item.kind === "review_comment_reply") {
    return false;
  }
  if (!body.trim()) {
    return false;
  }
  if (body.startsWith(botPrefix)) {
    return false;
  }
  if (markerCount(item.reactions, addressedMarker) > 0) {
    return false;
  }
  if (markerCount(item.reactions, pendingMarker) > 0) {
    return false;
  }
  return true;
}

function fetchUnified(repo: string, pr: number): UnifiedComment[] {
  const issue = runGh(`/repos/${repo}/issues/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const review = runGh(`/repos/${repo}/pulls/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const unified = issue.map(normalizeIssueComment).concat(review.map(normalizeReviewComment));
  unified.sort((a, b) => (a.created_at ?? "").localeCompare(b.created_at ?? ""));
  return unified;
}

function cmdQueue(args: QueueArgs) {
  const { addressed, pending } = reactionDefaults();
  const botPrefix = process.env.BOT_REPLY_PREFIX || "🤖";
  const items = fetchUnified(args.repo, args.pr);
  const newItems = items.filter((item) => isNewItem(item, addressed, pending, botPrefix));

  if (args.json) {
    console.log(JSON.stringify(newItems, null, 2));
    return;
  }

  if (newItems.length === 0) {
    console.log("No new comments.");
    return;
  }

  for (const item of newItems) {
    const text = item.body.split(/\s+/).join(" ").slice(0, 180);
    const loc = item.path ? ` ${item.path}:${item.line ?? 0}` : "";
    console.log(`[${item.kind}] id=${item.id} @${item.author}${loc}`);
    console.log(`url: ${item.url}`);
    console.log(`text: ${text}`);
    console.log("");
  }
}

function detectCommentEndpoints(repo: string, pr: number): Record<number, string> {
  const endpoints: Record<number, string> = {};
  const issue = runGh(`/repos/${repo}/issues/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const review = runGh(`/repos/${repo}/pulls/${pr}/comments?per_page=100`, {
    paginate: true,
  });

  for (const item of issue) {
    endpoints[item.id] = `/repos/${repo}/issues/comments/${item.id}/reactions`;
  }
  for (const item of review) {
    endpoints[item.id] = `/repos/${repo}/pulls/comments/${item.id}/reactions`;
  }
  return endpoints;
}

function parseIds(rawIds: string): number[] {
  return rawIds
    .split(",")
    .map((token) => token.trim())
    .filter(Boolean)
    .map((token) => Number.parseInt(token, 10));
}

function cmdMark(args: MarkArgs) {
  const { addressed, pending } = reactionDefaults();
  const marker = args.status === "pending" ? pending : addressed;
  const endpoints = detectCommentEndpoints(args.repo, args.pr);
  const ids = parseIds(args.ids);

  const missing = ids.filter((id) => !endpoints[id]);
  if (missing.length > 0) {
    console.error(`Unknown comment IDs for PR ${args.pr}: [${missing.join(", ")}]`);
    process.exit(2);
  }

  for (const id of ids) {
    runGh(endpoints[id], { method: "POST", fields: { content: marker } });
    console.log(`Marked ${args.status}: ${id}`);
  }
}

function requireArg(args: string[], flag: string): string {
  const idx = args.indexOf(flag);
  if (idx === -1 || idx + 1 >= args.length) {
    console.error(`Missing required argument: ${flag}`);
    process.exit(2);
  }
  return args[idx + 1];
}

function parseMarkStatus(args: string[]): "pending" | "addressed" {
  const idx = args.indexOf("--status");
  if (idx === -1) {
    return "addressed";
  }
  const value = args[idx + 1];
  if (value !== "pending" && value !== "addressed") {
    console.error("--status must be one of: pending, addressed");
    process.exit(2);
  }
  return value;
}

function main() {
  const argv = process.argv.slice(2);
  const command = argv[0];

  if (!command || (command !== "queue" && command !== "mark")) {
    console.error("Usage: bun gh_pr_ops.ts <queue|mark> [args]");
    process.exit(2);
  }

  if (command === "queue") {
    const args: QueueArgs = {
      repo: requireArg(argv, "--repo"),
      pr: Number.parseInt(requireArg(argv, "--pr"), 10),
      json: argv.includes("--json"),
    };
    cmdQueue(args);
    return;
  }

  const args: MarkArgs = {
    repo: requireArg(argv, "--repo"),
    pr: Number.parseInt(requireArg(argv, "--pr"), 10),
    ids: requireArg(argv, "--ids"),
    status: parseMarkStatus(argv),
  };
  cmdMark(args);
}

if (import.meta.main) {
  main();
}

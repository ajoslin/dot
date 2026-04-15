#!/usr/bin/env bun

import { execFileSync } from "node:child_process";

type Reactions = Record<string, number | null | undefined>;

type UnifiedComment = {
  kind: "issue_comment" | "review_comment" | "review_comment_reply" | "review_body";
  id: number;
  url: string | null;
  author: string | null;
  created_at: string | null;
  body: string;
  path: string | null;
  line: number | null;
  review_thread_resolved: boolean;
  review_state: string | null;
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

type RepoRef = {
  owner: string;
  name: string;
};

type CommentTarget = {
  kind: "issue_comment" | "review_comment" | "review_body";
  reactionEndpoint: string | null;
  reviewThreadId: string | null;
  reviewDismissalEndpoint: string | null;
};

type GraphqlReviewThreadComment = {
  databaseId: number | null;
};

type GraphqlReviewThreadNode = {
  id: string;
  isResolved: boolean;
  comments: {
    nodes: GraphqlReviewThreadComment[];
  };
};

type GraphqlReviewThreadsResponse = {
  data?: {
    repository?: {
      pullRequest?: {
        reviewThreads?: {
          nodes?: GraphqlReviewThreadNode[];
          pageInfo?: {
            hasNextPage?: boolean;
            endCursor?: string | null;
          };
        };
      };
    };
  };
};

type GhIssueComment = {
  id: number;
  html_url?: string | null;
  user?: { login?: string | null } | null;
  created_at?: string | null;
  body?: string | null;
  reactions?: Reactions | null;
};

type GhReviewComment = {
  id: number;
  in_reply_to_id?: number | null;
  html_url?: string | null;
  user?: { login?: string | null } | null;
  created_at?: string | null;
  body?: string | null;
  path?: string | null;
  line?: number | null;
  reactions?: Reactions | null;
};

type GhReview = {
  id: number;
  html_url?: string | null;
  user?: { login?: string | null } | null;
  submitted_at?: string | null;
  body?: string | null;
  state?: string | null;
};

function runGh(
  path: string,
  options?: {
    method?: "GET" | "POST" | "PUT";
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

function runGhGraphql(fields: Record<string, string | number | boolean>) {
  const cmd = ["api", "graphql"];
  for (const [key, value] of Object.entries(fields)) {
    const flag = key === "query" ? "-f" : "-F";
    cmd.push(flag, `${key}=${value}`);
  }
  const out = execFileSync("gh", cmd, { encoding: "utf8" });
  return JSON.parse(out);
}

function parseRepo(repo: string): RepoRef {
  const [owner, name, ...rest] = repo.split("/").map((token) => token.trim());
  if (!owner || !name || rest.length > 0) {
    console.error(`--repo must be in owner/name format. Received: ${repo}`);
    process.exit(2);
  }
  return { owner, name };
}

function normalizeIssueComment(item: GhIssueComment): UnifiedComment {
  return {
    kind: "issue_comment",
    id: item.id,
    url: item.html_url ?? null,
    author: item.user?.login ?? null,
    created_at: item.created_at ?? null,
    body: item.body ?? "",
    path: null,
    line: null,
    review_thread_resolved: false,
    review_state: null,
    reactions: item.reactions ?? {},
  };
}

function normalizeReviewComment(item: GhReviewComment): UnifiedComment {
  return {
    kind: item.in_reply_to_id ? "review_comment_reply" : "review_comment",
    id: item.id,
    url: item.html_url ?? null,
    author: item.user?.login ?? null,
    created_at: item.created_at ?? null,
    body: item.body ?? "",
    path: item.path ?? null,
    line: item.line ?? null,
    review_thread_resolved: false,
    review_state: null,
    reactions: item.reactions ?? {},
  };
}

function normalizeReview(item: GhReview): UnifiedComment {
  return {
    kind: "review_body",
    id: item.id,
    url: item.html_url ?? null,
    author: item.user?.login ?? null,
    created_at: item.submitted_at ?? null,
    body: item.body ?? "",
    path: null,
    line: null,
    review_thread_resolved: false,
    review_state: item.state ?? null,
    reactions: {},
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
  item: Pick<UnifiedComment, "kind" | "body" | "reactions" | "review_thread_resolved"> & {
    review_state?: UnifiedComment["review_state"];
  },
  addressedMarker: string,
  pendingMarker: string,
  botPrefix: string,
): boolean {
  const body = item.body || "";
  if (!body.trim()) {
    return false;
  }
  if (body.startsWith(botPrefix)) {
    return false;
  }
  if (item.kind === "review_comment_reply") {
    return false;
  }
  if (item.kind === "review_comment" && item.review_thread_resolved) {
    return false;
  }
  if (item.kind === "review_body") {
    return item.review_state !== "DISMISSED";
  }
  if (markerCount(item.reactions, addressedMarker) > 0) {
    return false;
  }
  if (markerCount(item.reactions, pendingMarker) > 0) {
    return false;
  }
  return true;
}

function fetchReviewThreadByCommentId(repo: string, pr: number): Record<number, { threadId: string; isResolved: boolean }> {
  const { owner, name } = parseRepo(repo);
  const result: Record<number, { threadId: string; isResolved: boolean }> = {};

  let cursor: string | null = null;
  do {
    const queryFields: Record<string, string | number | boolean> = {
      query: `
        query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
          repository(owner: $owner, name: $name) {
            pullRequest(number: $number) {
              reviewThreads(first: 100, after: $cursor) {
                nodes {
                  id
                  isResolved
                  comments(first: 100) {
                    nodes {
                      databaseId
                    }
                  }
                }
                pageInfo {
                  hasNextPage
                  endCursor
                }
              }
            }
          }
        }
      `,
      owner,
      name,
      number: pr,
    };
    if (cursor) {
      queryFields.cursor = cursor;
    }
    const response = runGhGraphql(queryFields) as GraphqlReviewThreadsResponse;

    const reviewThreads = response.data?.repository?.pullRequest?.reviewThreads;
    const nodes = reviewThreads?.nodes ?? [];
    for (const thread of nodes) {
      const commentNodes = thread.comments?.nodes ?? [];
      for (const comment of commentNodes) {
        if (typeof comment.databaseId === "number") {
          result[comment.databaseId] = { threadId: thread.id, isResolved: thread.isResolved };
        }
      }
    }

    const pageInfo = reviewThreads?.pageInfo;
    cursor = pageInfo?.hasNextPage ? (pageInfo.endCursor ?? null) : null;
  } while (cursor);

  return result;
}

function fetchUnified(repo: string, pr: number): UnifiedComment[] {
  const issue = runGh(`/repos/${repo}/issues/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const review = runGh(`/repos/${repo}/pulls/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const reviews = runGh(`/repos/${repo}/pulls/${pr}/reviews?per_page=100`, {
    paginate: true,
  });
  const reviewThreadsByCommentId = fetchReviewThreadByCommentId(repo, pr);
  const normalizedReview = review.map(normalizeReviewComment).map((item) => {
    const thread = reviewThreadsByCommentId[item.id];
    return {
      ...item,
      review_thread_resolved: thread?.isResolved ?? false,
    };
  });
  const unified = issue.map(normalizeIssueComment).concat(normalizedReview, reviews.map(normalizeReview));
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

function detectCommentTargets(repo: string, pr: number): Record<number, CommentTarget> {
  const targets: Record<number, CommentTarget> = {};
  const issue = runGh(`/repos/${repo}/issues/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const review = runGh(`/repos/${repo}/pulls/${pr}/comments?per_page=100`, {
    paginate: true,
  });
  const reviews = runGh(`/repos/${repo}/pulls/${pr}/reviews?per_page=100`, {
    paginate: true,
  });
  const reviewThreadsByCommentId = fetchReviewThreadByCommentId(repo, pr);

  for (const item of issue) {
    targets[item.id] = {
      kind: "issue_comment",
      reactionEndpoint: `/repos/${repo}/issues/comments/${item.id}/reactions`,
      reviewThreadId: null,
      reviewDismissalEndpoint: null,
    };
  }
  for (const item of review) {
    targets[item.id] = {
      kind: "review_comment",
      reactionEndpoint: `/repos/${repo}/pulls/comments/${item.id}/reactions`,
      reviewThreadId: reviewThreadsByCommentId[item.id]?.threadId ?? null,
      reviewDismissalEndpoint: null,
    };
  }
  for (const item of reviews) {
    targets[item.id] = {
      kind: "review_body",
      reactionEndpoint: null,
      reviewThreadId: null,
      reviewDismissalEndpoint: `/repos/${repo}/pulls/${pr}/reviews/${item.id}/dismissals`,
    };
  }
  return targets;
}

function resolveReviewThread(threadId: string) {
  runGhGraphql({
    query: `
      mutation($threadId: ID!) {
        resolveReviewThread(input: { threadId: $threadId }) {
          thread {
            id
            isResolved
          }
        }
      }
    `,
    threadId,
  });
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
  const targets = detectCommentTargets(args.repo, args.pr);
  const ids = parseIds(args.ids);

  const missing = ids.filter((id) => !targets[id]);
  if (missing.length > 0) {
    console.error(`Unknown comment IDs for PR ${args.pr}: [${missing.join(", ")}]`);
    process.exit(2);
  }

  const resolvedThreads = new Set<string>();

  for (const id of ids) {
    const target = targets[id];
    if (target.kind === "review_body") {
      if (args.status === "pending") {
        console.log(`Skipped pending for review body ${id}: no reaction endpoint`);
        continue;
      }

      runGh(target.reviewDismissalEndpoint!, {
        method: "PUT",
        fields: {
          message: "Addressed",
          event: "DISMISS",
        },
      });
      console.log(`Dismissed review ${id}`);
      continue;
    }

    if (args.status === "addressed" && target.kind === "review_comment" && target.reviewThreadId) {
      if (!resolvedThreads.has(target.reviewThreadId)) {
        resolveReviewThread(target.reviewThreadId);
        resolvedThreads.add(target.reviewThreadId);
      }
      console.log(`Resolved review thread for comment ${id}`);
      continue;
    }

    runGh(target.reactionEndpoint!, { method: "POST", fields: { content: marker } });
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

import { describe, expect, it } from "bun:test";
import { isNewItem } from "./gh_pr_ops";

describe("isNewItem", () => {
  it("returns true for a fresh comment", () => {
    const item = {
      kind: "issue_comment" as const,
      body: "please fix this",
      review_thread_resolved: false,
      reactions: { "+1": 0, eyes: 0 },
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(true);
  });

  it("returns false when already addressed", () => {
    const item = {
      kind: "issue_comment" as const,
      body: "already handled",
      review_thread_resolved: false,
      reactions: { "+1": 1 },
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("returns false when pending", () => {
    const item = {
      kind: "issue_comment" as const,
      body: "working on this",
      review_thread_resolved: false,
      reactions: { eyes: 1 },
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("returns false for bot-prefixed replies", () => {
    const item = {
      kind: "issue_comment" as const,
      body: "🤖 Addressed in abc123",
      review_thread_resolved: false,
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("returns false for review comment replies", () => {
    const item = {
      kind: "review_comment_reply" as const,
      body: "please see above",
      review_thread_resolved: false,
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("returns false for resolved review threads", () => {
    const item = {
      kind: "review_comment" as const,
      body: "please update this",
      review_thread_resolved: true,
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("returns true for a fresh review body", () => {
    const item = {
      kind: "review_body" as const,
      body: "<!-- BUGBOT_REVIEW -->\nPlease fix this before merge.",
      review_thread_resolved: false,
      review_state: "COMMENTED",
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(true);
  });

  it("returns false for an empty review body", () => {
    const item = {
      kind: "review_body" as const,
      body: "   ",
      review_thread_resolved: false,
      review_state: "COMMENTED",
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("returns false for a bot-prefixed review body", () => {
    const item = {
      kind: "review_body" as const,
      body: "🤖 Addressed in abc123",
      review_thread_resolved: false,
      review_state: "COMMENTED",
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });

  it("ignores reaction markers for review bodies", () => {
    const item = {
      kind: "review_body" as const,
      body: "Still needs work.",
      review_thread_resolved: false,
      review_state: "COMMENTED",
      reactions: { "+1": 1, eyes: 1 },
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(true);
  });

  it("returns false for dismissed review bodies", () => {
    const item = {
      kind: "review_body" as const,
      body: "This was already handled.",
      review_thread_resolved: false,
      review_state: "DISMISSED",
      reactions: {},
    };
    expect(isNewItem(item, "+1", "eyes", "🤖")).toBe(false);
  });
});

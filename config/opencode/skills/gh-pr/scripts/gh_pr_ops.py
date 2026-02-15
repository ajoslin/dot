#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys


def run_gh(path, method="GET", fields=None):
    cmd = ["gh", "api", "--method", method, path]
    if fields:
        for key, value in fields.items():
            cmd += ["-f", f"{key}={value}"]
    out = subprocess.check_output(cmd, text=True)
    return json.loads(out)


def normalize_issue_comment(item):
    return {
        "kind": "issue_comment",
        "id": item["id"],
        "url": item.get("html_url"),
        "author": item.get("user", {}).get("login"),
        "created_at": item.get("created_at"),
        "body": item.get("body") or "",
        "path": None,
        "line": None,
        "reactions": item.get("reactions", {}),
    }


def normalize_review_comment(item):
    return {
        "kind": "review_comment_reply" if item.get("in_reply_to_id") else "review_comment",
        "id": item["id"],
        "url": item.get("html_url"),
        "author": item.get("user", {}).get("login"),
        "created_at": item.get("created_at"),
        "body": item.get("body") or "",
        "path": item.get("path"),
        "line": item.get("line"),
        "reactions": item.get("reactions", {}),
    }


def marker_count(reactions, marker):
    if not reactions:
        return 0
    return int(reactions.get(marker, 0) or 0)


def is_new_item(item, marker, bot_prefix):
    body = item.get("body") or ""
    if item.get("kind") == "review_comment_reply":
        return False
    if not body.strip():
        return False
    if body.startswith(bot_prefix):
        return False
    if marker_count(item.get("reactions"), marker) > 0:
        return False
    return True


def fetch_unified(repo, pr):
    issue = run_gh(f"/repos/{repo}/issues/{pr}/comments?per_page=100")
    review = run_gh(f"/repos/{repo}/pulls/{pr}/comments?per_page=100")
    unified = [normalize_issue_comment(x) for x in issue]
    unified += [normalize_review_comment(x) for x in review]
    unified.sort(key=lambda x: x.get("created_at") or "")
    return unified


def cmd_queue(args):
    marker = os.getenv("MARKER_REACTION", "hooray")
    bot_prefix = os.getenv("BOT_REPLY_PREFIX", "🤖")
    items = fetch_unified(args.repo, args.pr)
    new_items = [x for x in items if is_new_item(x, marker, bot_prefix)]

    if args.json:
        print(json.dumps(new_items, indent=2))
        return

    if not new_items:
        print("No new comments.")
        return

    for item in new_items:
        text = " ".join((item.get("body") or "").split())[:180]
        loc = f" {item['path']}:{item.get('line') or 0}" if item.get("path") else ""
        print(f"[{item['kind']}] id={item['id']} @{item.get('author')}{loc}")
        print(f"url: {item.get('url')}")
        print(f"text: {text}")
        print()


def detect_comment_endpoints(repo, pr):
    endpoints = {}
    for item in run_gh(f"/repos/{repo}/issues/{pr}/comments?per_page=100"):
        endpoints[item["id"]] = f"/repos/{repo}/issues/comments/{item['id']}/reactions"
    for item in run_gh(f"/repos/{repo}/pulls/{pr}/comments?per_page=100"):
        endpoints[item["id"]] = f"/repos/{repo}/pulls/comments/{item['id']}/reactions"
    return endpoints


def parse_ids(raw_ids):
    result = []
    for token in raw_ids.split(","):
        token = token.strip()
        if token:
            result.append(int(token))
    return result


def cmd_mark(args):
    marker = os.getenv("MARKER_REACTION", "hooray")
    endpoints = detect_comment_endpoints(args.repo, args.pr)
    ids = parse_ids(args.ids)

    missing = [cid for cid in ids if cid not in endpoints]
    if missing:
        print(f"Unknown comment IDs for PR {args.pr}: {missing}", file=sys.stderr)
        sys.exit(2)

    for cid in ids:
        path = endpoints[cid]
        run_gh(path, method="POST", fields={"content": marker})
        print(f"Marked addressed: {cid}")


def main():
    parser = argparse.ArgumentParser(description="Simple gh-pr helpers")
    sub = parser.add_subparsers(dest="command", required=True)

    q = sub.add_parser("queue", help="List new PR comments")
    q.add_argument("--repo", required=True, help="owner/repo")
    q.add_argument("--pr", required=True, type=int, help="PR number")
    q.add_argument("--json", action="store_true", help="Output JSON")
    q.set_defaults(func=cmd_queue)

    m = sub.add_parser("mark", help="Mark one or many comments addressed")
    m.add_argument("--repo", required=True, help="owner/repo")
    m.add_argument("--pr", required=True, type=int, help="PR number")
    m.add_argument("--ids", required=True, help="Comma-separated comment IDs")
    m.set_defaults(func=cmd_mark)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

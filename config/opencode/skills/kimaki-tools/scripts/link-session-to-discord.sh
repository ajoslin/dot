#!/usr/bin/env bash
set -euo pipefail

SESSION_ID="${OPENCODE_SESSION_ID:-}"
PROJECT_DIR="$(pwd)"
PROMPT=""
USER_NAME=""
THREAD_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)
      SESSION_ID="${2:-}"
      shift 2
      ;;
    --project)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    --prompt)
      PROMPT="${2:-}"
      shift 2
      ;;
    --user)
      USER_NAME="${2:-}"
      shift 2
      ;;
    --thread-id)
      THREAD_ID="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  link-session-to-discord.sh --session-id <id> [--project <path>] [--prompt <text>] [--user <name>] [--thread-id <id>]

Examples:
  link-session-to-discord.sh --session-id ses_abc --project "$(pwd)" --user "lp"
  link-session-to-discord.sh --session-id ses_abc --thread-id 1472000000000000000
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SESSION_ID" ]]; then
  echo "Missing session id. Use --session-id <id> or set OPENCODE_SESSION_ID." >&2
  exit 1
fi

if [[ -z "$PROMPT" ]]; then
  PROMPT="Linking existing OpenCode session $SESSION_ID"
fi

PROJECT_DIR="$(python3 - <<'PY' "$PROJECT_DIR"
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
)"

PROJECTS_JSON="$(npx -y kimaki project list --json 2>/dev/null)"

CHANNEL_ID="$(node -e '
const input = process.argv[1]
const projectDir = process.argv[2]
const rows = JSON.parse(input)

function sameOrWithin(target, root) {
  return target === root || target.startsWith(root + "/")
}

let best = null
for (const row of rows) {
  const dir = row.directory
  if (!dir) continue
  if (sameOrWithin(projectDir, dir) || sameOrWithin(dir, projectDir)) {
    if (!best || dir.length > best.directory.length) best = row
  }
}

process.stdout.write(best?.channel_id || "")
' "$PROJECTS_JSON" "$PROJECT_DIR")"

if [[ -z "$CHANNEL_ID" ]]; then
  echo "No Kimaki project mapping found for: $PROJECT_DIR" >&2
  echo "Fix: npx -y kimaki project add \"$PROJECT_DIR\"" >&2
  exit 1
fi

THREAD_URL=""
if [[ -z "$THREAD_ID" ]]; then
  SEND_CMD=(npx -y kimaki send --channel "$CHANNEL_ID" --prompt "$PROMPT" --notify-only)
  if [[ -n "$USER_NAME" ]]; then
    SEND_CMD+=(--user "$USER_NAME")
  fi

  SEND_OUTPUT="$(${SEND_CMD[@]} 2>&1)"

  THREAD_URL="$(node -e '
const s = process.argv[1]
const m = s.match(/https:\/\/discord\.com\/channels\/\d+\/\d+/)
process.stdout.write(m ? m[0] : "")
' "$SEND_OUTPUT")"

  THREAD_ID="$(node -e '
const url = process.argv[1]
const m = url.match(/\/channels\/\d+\/(\d+)/)
process.stdout.write(m ? m[1] : "")
' "$THREAD_URL")"

  if [[ -z "$THREAD_ID" ]]; then
    echo "Failed to parse thread ID from kimaki send output." >&2
    echo "$SEND_OUTPUT" >&2
    exit 1
  fi
fi

DB_OUTPUT="$(npx -y kimaki sqlitedb 2>/dev/null)"
DB_PATH="$(node -e '
const s = process.argv[1]
const m = s.match(/\/(Users|home)\/.+\.db/)
if (m) process.stdout.write(m[0])
' "$DB_OUTPUT")"

if [[ -z "$DB_PATH" ]]; then
  echo "Failed to resolve Kimaki sqlite database path." >&2
  echo "$DB_OUTPUT" >&2
  exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 is required for session linking but is not installed." >&2
  exit 1
fi

sqlite3 "$DB_PATH" "INSERT INTO thread_sessions (thread_id, session_id) VALUES ('$THREAD_ID', '$SESSION_ID') ON CONFLICT(thread_id) DO UPDATE SET session_id=excluded.session_id;"

echo "Linked session to Discord thread"
echo "project_dir=$PROJECT_DIR"
echo "channel_id=$CHANNEL_ID"
echo "thread_id=$THREAD_ID"
if [[ -n "$THREAD_URL" ]]; then
  echo "thread_url=$THREAD_URL"
fi
echo "session_id=$SESSION_ID"

echo
echo "Verification:"
npx -y kimaki session list --project "$PROJECT_DIR" --json

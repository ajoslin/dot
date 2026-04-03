# OpenCode Storage Format

Reference for the local data layout. The skill uses direct `sqlite3` and file
queries against this structure.

## Data Root

```
~/.local/share/opencode/
├── opencode.db          # Main SQLite database (sessions, messages, parts, todos)
├── opencode.db-shm      # SQLite shared memory
├── opencode.db-wal      # SQLite write-ahead log
├── plans/               # Saved plan markdown files
│   └── <timestamp>-<slug>.md
├── snapshot/             # Internal file snapshots per project (for undo/diff)
│   └── <project-id>/
├── storage/
│   ├── session_diff/     # Changed-file diffs per session
│   │   └── <session-id>.json
│   ├── session/
│   │   └── global/       # Legacy session JSON (older installs)
│   └── project/
│       └── global.json   # Legacy project registry
├── tool-output/          # Cached tool outputs
├── log/                  # Application logs
└── bin/                  # Bundled binaries (pyright, etc.)
```

## State Root

```
~/.local/state/opencode/
├── prompt-history.jsonl  # Raw prompt history (one JSON object per line)
└── frecency.jsonl        # File access frequency/recency data
```

## Config Root

```
~/.config/opencode/
├── opencode.json         # Main config
├── tui.json              # TUI config
├── agents/               # Custom agent definitions
├── commands/             # Custom command definitions
├── skills/               # Global skills
├── tools/                # Custom tool definitions
└── plugins/              # Local plugins
```

## Project Link

Each git repo tracked by OpenCode has a file:

```
<repo>/.git/opencode      # Contains the project ID hash
```

This ID maps to the `project` table in the database.

## SQLite Schema

### project

| Column       | Type    | Notes                          |
|-------------|---------|--------------------------------|
| id          | TEXT PK | SHA hash of worktree path      |
| worktree    | TEXT    | Absolute path to git worktree  |
| name        | TEXT    | May be NULL; derive from path  |
| time_created| INTEGER | Unix timestamp                 |
| time_updated| INTEGER | Unix timestamp                 |

### session

| Column        | Type    | Notes                                    |
|--------------|---------|------------------------------------------|
| id           | TEXT PK | e.g. `ses_xxx`                           |
| project_id   | TEXT FK | References project.id                    |
| parent_id    | TEXT    | NULL for main sessions, set for subagent |
| directory    | TEXT    | Working directory for the session        |
| title        | TEXT    | Auto-generated or user-set title         |
| summary      | TEXT    | Compaction summary                       |
| time_created | INTEGER | Unix timestamp                           |
| time_updated | INTEGER | Unix timestamp                           |

### message

| Column        | Type    | Notes                                |
|--------------|---------|--------------------------------------|
| id           | TEXT PK | e.g. `msg_xxx`                       |
| session_id   | TEXT FK | References session.id                |
| data         | TEXT    | JSON blob with role, model, metadata |
| time_created | INTEGER | Unix timestamp                       |
| time_updated | INTEGER | Unix timestamp                       |

Key JSON fields in `message.data`:
- `$.role` — `"user"` or `"assistant"`

### part

| Column        | Type    | Notes                                    |
|--------------|---------|------------------------------------------|
| id           | TEXT PK | e.g. `prt_xxx`                           |
| message_id   | TEXT FK | References message.id                    |
| session_id   | TEXT FK | References session.id                    |
| data         | TEXT    | JSON blob with type, text, tool payloads |
| time_created | INTEGER | Unix timestamp                           |
| time_updated | INTEGER | Unix timestamp                           |

Key JSON fields in `part.data`:
- `$.type` — `"text"`, `"tool-invocation"`, `"tool-result"`, etc.
- `$.text` — Text content (when type is `"text"`)

### todo

| Column        | Type    | Notes                         |
|--------------|---------|-------------------------------|
| id           | TEXT PK |                               |
| session_id   | TEXT FK | References session.id         |
| content      | TEXT    | Todo item text                |
| status       | TEXT    | pending, in_progress, etc.    |
| priority     | TEXT    | high, medium, low             |
| time_created | INTEGER | Unix timestamp                |
| time_updated | INTEGER | Unix timestamp                |

## Useful Raw Queries

### Count main sessions
```sql
SELECT COUNT(*) FROM session WHERE parent_id IS NULL;
```

### User messages with text
```sql
SELECT
  s.id AS session_id,
  COALESCE(s.title, 'untitled') AS session_title,
  m.id AS message_id,
  m.time_created AS timestamp,
  json_extract(p.data, '$.text') AS text
FROM session s
JOIN message m ON m.session_id = s.id
JOIN part p ON p.message_id = m.id
WHERE s.parent_id IS NULL
  AND json_extract(m.data, '$.role') = 'user'
  AND json_extract(p.data, '$.type') = 'text'
ORDER BY m.time_created DESC;
```

### Session diffs
```
~/.local/share/opencode/storage/session_diff/<session-id>.json
```
Contains arrays of file paths changed during the session.

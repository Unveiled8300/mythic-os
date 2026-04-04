---
name: handoff
description: >
  Use this skill when the user says "/handoff", "Vendor Manager: HANDOFF", "prepare handoff",
  "context is filling up", "switching to Cursor", "switching to VS Code", "switching IDEs",
  "session ending", "save the state", or when the 5-hour token limit warning appears.
  Creates or appends HANDOFF.md with full session state so work can resume cleanly in another
  IDE or the next session.
version: 1.0.0
---

# /handoff — Vendor Manager Handoff Manifest

You are the Vendor Manager preparing the session handoff.

## Trigger Conditions

This skill should be run when:
- The 5-hour token limit warning appears — run immediately before accepting further work
- Founder is switching to Cursor, VS Code, Warp, or another IDE
- Context window is ≥ 70% (run alongside `/compact`)
- Founder explicitly requests a handoff or session save

## Step 1: Decide Overwrite vs. Append

Check if `HANDOFF.md` exists at the project root:
- **Does not exist** → create it fresh
- **Exists, most recent block timestamp is from this session** → overwrite that block
- **Exists, most recent block timestamp is from a prior session** → append a new block below; never delete prior records

## Step 2: Gather Current State

Collect the following before writing:

1. **Context usage** — run `/usage` or note current context % if available
2. **Git branch** — run `git branch --show-current` (write "no VCS" if not a git repo)
3. **Last successful command** — the most recent terminal command that completed cleanly and its result
4. **Modified files** — run `git status` or review session history for files touched this session
5. **SPRINT.md state** — current status of all Atomic Tasks (pending / in-progress / done / blocked)
6. **MCP connections** — list any MCP connectors used this session and their last known state

## Step 3: Write the Handoff Block

```markdown
## HANDOFF MANIFEST — [project-name] — [ISO 8601 timestamp]

### Session State
- Context Usage at Handoff: [X]%
- Token Usage at Handoff: [X]% of 5-hour limit (if known)
- Trigger: [5-Hour Token Limit Warning | Founder Request | IDE Switch — [IDE name]]
- Current Branch: [git branch output or "no VCS"]
- Last Successful Command: `[command]` → [one-line result summary]

### Mid-Edit Files
| File | Status | Last Action |
|------|--------|-------------|
| [path] | [modified / created / deleted] | [what was done] |

### Pending Tasks (snapshot from SPRINT.md)
| Task ID | Description | Status | Blocked By |
|---------|-------------|--------|------------|
| T-[N] | [description] | [pending / in-progress / blocked] | [blocker or none] |

### Warnings
| Warning | Detail |
|---------|--------|
| [e.g., Uncommitted changes] | [files] |

(Remove Warnings section if no warnings.)

### State of the Union
[2–5 sentences: what was being worked on when the handoff was triggered, decisions just made,
what the next action should be, and what will NOT be obvious from reading the files alone.]

### Resume Instructions
1. Open [IDE]: load project from [absolute project path]
2. Run: [validation command — e.g., `npm install && npm run dev`]
3. Verify these files are as expected: [2–5 critical file paths]
4. Next task: T-[N] — [task description from SPRINT.md]
5. First command to run: [the specific command to pick up where we left off]

### Active MCP Connections
| Connector | Status | Last Used |
|-----------|--------|-----------|
| [name] | [authenticated / needs-reauth / unreachable] | [timestamp or "this session"] |
```

## Step 4: Apply IDE-Specific Placement (If IDE Switch)

If the trigger is switching to a specific IDE, prepare the context file:

| IDE | Action |
|-----|--------|
| **Cursor** | Copy `CLAUDE.md` to project root (or append to `.cursorrules` if it exists — confirm with Founder first) |
| **VS Code** | `CLAUDE.md` at project root; check if `.github/copilot-instructions.md` should be created |
| **Warp** | Export State of the Union as a Warp notebook block (paste the State of the Union paragraph) |
| **Opencode / other** | `CLAUDE.md` at project root (default behavior) |

Confirm with Founder before writing any IDE-specific files:
> "For [IDE], I'll write [files]. Shall I proceed?"
Wait for confirmation.

## Step 5: Asset Normalization

Before finalizing HANDOFF.md, strip any terminal artifacts from the content:
- ANSI color codes (`\x1b[...m`)
- Spinner characters (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`)
- Bare carriage returns (`\r` not followed by `\n`)
- Claude thinking tags (`<thinking>...</thinking>`)

Result must be clean, readable plain text.

## Step 5.5: Trigger Reflect if Errors Were Captured

Before finalizing, check if any new error records were captured this session:

1. List files in `~/.claude/brain/log/errors/` — check for files with today's date in the filename
2. If new errors exist (created during this session):
   - Run a **lightweight reflect**: scan only the new error files, check for patterns against existing `brain/patterns/`, update `brain/index.md` stats
   - Do NOT run the full /reflect ceremony (no ADR review, no sprint health, no Founder approval loop)
   - Just: capture → pattern-check → stats update
3. If no new errors: skip this step

This ensures institutional learning happens automatically at session boundaries.

## Step 6: Report

After writing HANDOFF.md:

```
Handoff manifest written — [project-name]
File: [project-root]/HANDOFF.md
Trigger: [trigger type]

Pending tasks captured: [N]
Modified files documented: [N]
MCP connectors logged: [N]

Next session resume instructions are in HANDOFF.md under "Resume Instructions".
```

## Safety Notes

- **NEVER include `.env`** in any export — only `.env.example` with values redacted
- Do NOT modify `settings.json` — report connector states and recommend; Founder applies changes
- If MCP connector needs re-authentication, say: "[Connector] needs re-authentication. Go to [settings location] to refresh credentials."

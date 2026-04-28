---
name: recall
description: Summarises Claude Code sessions by intent and writes structured notes into Obsidian — a per-project log, current-state snapshot, and global timeline. Use when asked to "log my sessions", "what did I work on today", "recap this week", "write up yesterday", "summarise today's sessions", or when given a specific date. Also triggers /scout automatically when enough sessions accumulate.
allowed-tools: Read, Write, Grep, Bash(find:*), Bash(date:*), Bash(mkdir:*), Bash(wc:*), Bash(awk:*), Bash(sed:*), Bash(sort:*), Skill(*)
---

You summarise Claude Code sessions for a given time range and write structured notes into Obsidian.

## Rules

- Never delete files
- Append to log files — never overwrite them
- State files reflect current reality — read first, then overwrite with updated content
- index.md reflects current reality — read first, then overwrite with updated content

## Status reporting

At every step, print what you are doing so the user can see progress. If anything fails, print clearly:

- `✓` for success
- `✗ ERROR:` followed by what failed and why
- `⚠ WARNING:` for non-fatal issues (e.g. session skipped, file already exists)

At the end always print a summary block even if nothing was processed.

## Error handling

**Invalid argument:** If `$ARGUMENTS` is set but does not match any recognised pattern, print:

```
✗ ERROR: Unrecognised argument "{value}" — valid options: today | yesterday | this week | last week | YYYY-MM-DD
```

and stop immediately.

**Missing ~/.claude/projects:** If the directory does not exist when searched in Step 2, print:

```
✗ ERROR: ~/.claude/projects not found — is Claude Code installed and has it been run at least once?
```

and stop.

**Partial failure mid-run:** If Steps 4, 5, or 6 produce any errors:

- Do NOT update `~/Recall/.processed` — leave it at its previous value so the next run reprocesses the affected sessions
- Print `✗ ERROR` for each failure and continue to the next project or step
- Report all failures in the Errors line of the summary

**Unexpected errors:** If any command or file operation fails in a way not covered by a specific step:

- Print: `✗ ERROR: Unexpected failure in Step {N} — {command} returned: {error}`
- Bookkeeping failures (log, index, schedule.log): print the error and continue — notes are more important than bookkeeping
- Core write failures (Step 4 project files): skip that project, continue to the next, count as an error
- Never silently swallow an error — always surface it

## Time range

The user passed: $ARGUMENTS

Parse it as:

- `today` → sessions from today
- `yesterday` → sessions from yesterday
- `this week` → last 7 days
- `last week` → the week before this one
- `YYYY-MM-DD` → that specific date
- no argument → default to today

If `$ARGUMENTS` is set but matches none of the above, apply the invalid argument rule from Error handling and stop.

## Step 1 — Check last processed timestamp

Print: `→ Checking ~/Recall/.processed...`

Read `~/Recall/.processed` if it exists. It contains a single ISO timestamp like `2026-04-11T18:00:23`.

- If found → print `  Last run: {timestamp}. Will only process sessions after this.`
- If not found → print `  No .processed file — first run, processing full range.`
- If user explicitly passed a date argument like `this week` or `yesterday` → ignore `.processed`, print `  Explicit range passed — ignoring .processed, processing full range.`

If the file exists but is unreadable → print `✗ ERROR: Could not read ~/Recall/.processed — {reason}. Aborting.` and stop.

## Step 2 — Find sessions

Print: `→ Searching ~/.claude/projects for sessions in range...`

Use `find ~/.claude/projects -name "*.jsonl" ! -path "*/subagents/*"` to exclude subagent files.

Print: `  Skipped {n} subagent files (fragments of parent sessions, no user intent).`

Filter by internal timestamps. Use `head -c 3000` on each file to read the opening — the `ai-title` and first user message are enough to classify intent.

- If no sessions found → print `  ⚠ No sessions found for this time range. Nothing to process.` then print the summary block and stop.
- If sessions found → print `  Found {n} sessions to process.`
- If a session file can't be read → print `  ⚠ WARNING: Could not read {filename} — skipping.`

## Step 3 — Classify and detect project for each session

Print: `→ Classifying sessions...`

For each session print: `  {filename} → {intent} → {project}`

### Intent — pick the single best:

- `decisions` — choosing between approaches, tools, or directions
- `bug-fixes` — diagnosing and fixing something broken
- `design` — planning architecture, structure, or system design
- `research` — exploring a tool, library, concept, or approach
- `implementation` — building or writing something concrete
- `other` — anything that doesn't fit above

### Project name detection — in priority order:

1. **Working directory path**: run `grep -m1 "cwd\|\"pwd\"\|Desktop" {session_file}` — extract the deepest meaningful folder from the path (e.g. `/Users/kavya/Desktop/DEV_MODE/skill-scout/` → `skill-scout`)
2. **Git remote**: run `grep -m1 "remote\|origin\|github.com" {session_file}` — extract repo name from the URL (e.g. `git@github.com:user/skill-scout.git` → `skill-scout`)
3. **Session content**: if the `ai-title` or first user message clearly names a project, use that
4. **Folder name fallback**: use the last meaningful segment of the `~/.claude/projects/` folder name only if none of the above work (e.g. `-Users-kavya-Desktop-DEV_MODE` → `DEV-MODE`)

Print the detection method used: `  → project detected via {cwd | git remote | content | folder fallback}: {project}`

## Step 4 — Write two files per project

Print: `→ Writing to ~/Recall/Projects/...`

---

### File A: `~/Recall/Projects/{project-name}/{project-name}-log.md`

Append only. Never overwrite.

Each entry uses the heading format: `## [YYYY-MM-DD] intent | topic`

Topic is a short slug inferred from session content (e.g. `recall-skill-permissions`, `git-branch-cleanup`).

```
## [YYYY-MM-DD] intent | topic

**Session:** {session filename}

{fill the matching intent template below}

---
```

On success print: `  ✓ Appended to {project-name}-log.md`
On failure print: `  ✗ ERROR: Could not write {project-name}-log.md — {reason}`

---

### File B: `~/Recall/Projects/{project-name}/{project-name}-state.md`

Current truth — read the existing file first if it exists, then write the updated version in full. Do not append.

```
---
project: {project-name}
status: active | stalled | complete
last-updated: {YYYY-MM-DD}
tags: [{comma-separated intent tags from recent sessions}]
related: [{other project names referenced in this session, if any}]
---

# {project-name}

## What it is
{one paragraph}

## Current state
{what is built and working right now}

## Components / skills / scripts
{list each with one-line description}

## Key decisions
{bullet list, most recent first}

## What has been tried and didn't work
{bullet list}

## Open questions
{unresolved questions}

## Related projects
{links to other ~/Recall/Projects/ pages that this project references or depends on}

## Last updated
{date}
```

**Cross-project linking:** Before writing, scan the session content and the existing state file for mentions of other project names known from `~/Recall/index.md`. List any found under `## Related projects` as markdown links: `- [{project-name}](../{project-name}/{project-name}-state.md)`.

On success print: `  ✓ Updated {project-name}-state.md`
On failure print: `  ✗ ERROR: Could not write {project-name}-state.md — {reason}`

---

## Step 5 — Append to global log

Print: `→ Updating ~/Recall/log.md...`

Append one line per session processed to `~/Recall/log.md`. Create the file if it doesn't exist.

Each line uses the format: `## [YYYY-MM-DD] {intent} | {project} | {topic-slug}`

This gives a single chronological timeline across all projects, grep-able with standard unix tools.

On success print: `  ✓ Appended {n} entries to ~/Recall/log.md`
On failure print: `  ✗ ERROR: Could not write ~/Recall/log.md — {reason}`

## Step 6 — Update index.md

Print: `→ Updating ~/Recall/index.md...`

Read `~/Recall/index.md` if it exists. For each project processed this run, update its entry (or add it if new). Each entry is one line under `## Projects`:

```
- [{project-name}](Projects/{project-name}/{project-name}-log.md) — {one sentence: what this project is and what it does} — last updated {YYYY-MM-DD}
```

Write the full file back (this is a catalog, not a log — it reflects current state).

If the file does not exist, create it:

```
# Recall Index

## Projects
{entries}

## Scout candidates
See [Scout/](Scout/) for automation candidates flagged by /scout.
```

On success print: `  ✓ Updated ~/Recall/index.md`
On failure print: `  ✗ ERROR: Could not write index.md — {reason}`

## Step 7 — Update processed timestamp

Only update `~/Recall/.processed` if no errors occurred in Steps 4, 5, or 6. If any errors occurred, leave `.processed` at its previous value so the next run reprocesses the affected sessions — do not silently drop failed sessions.

If updating: write current timestamp to `~/Recall/.processed`.
Print: `  ✓ Updated ~/Recall/.processed`
If skipping due to errors: print `  ⚠ .processed not updated — errors occurred, next run will reprocess affected sessions`

Append to `~/Recall/schedule.log`:

```
[{timestamp}] recall: processed {n} sessions, updated {n} files
```

Print: `  ✓ Logged to ~/Recall/schedule.log`

If either write fails, print the error but do not abort — the notes are already written.

## Step 8 — Verify before summarising

Before printing the summary, confirm each of the following. For any item not met, print `✗ ERROR` — do not mark it as success in the summary.

- [ ] Every session found was either written to a project log or explicitly skipped with a warning
- [ ] Every project written has both an updated log file and an updated state file
- [ ] `~/Recall/log.md` was appended with one line per session processed
- [ ] `~/Recall/index.md` reflects all projects touched this run
- [ ] `~/Recall/.processed` was either updated (clean run) or intentionally left unchanged (errors occurred)

## Step 9 — Print summary

Always print this block, even if nothing was processed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
recall complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Time range : {range}
Sessions   : {n} processed, {n} skipped
Projects   : {list of projects written}
Files      : {list of files written}
Next run   : picks up sessions after {timestamp}
Errors     : {n} — {list if any, else "none"}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 10 — Adaptive scout trigger

Count sessions processed this run. Read `~/Recall/.scout_processed` if it exists.

| Sessions this run | Call /scout if...                                          |
| ----------------- | ---------------------------------------------------------- |
| 1–2               | No `.scout_processed` file, or last scout was > 7 days ago |
| 3–5               | Last scout was > 2 days ago                                |
| 6+                | Always                                                     |

If threshold met:

- Print: `→ Threshold met ({n} sessions) — invoking /scout {time-range-argument}...`
- Invoke `/scout` with the same time range argument that was passed to recall

If threshold not met:

- Print: `⚠ Scout skipped — {n} sessions, last scout {X} days ago (threshold not met)`

---

## Intent templates (for the log file)

### decisions

```
### What was the choice between?
{extract from conversation}

### Why this path was chosen
{extract from conversation}

### What was ruled out and why
{extract from conversation}

### Assumptions being made
{extract from conversation}

### When to revisit
{extract or note if unclear}
```

### bug-fixes

```
### Symptom
{extract from conversation}

### First guess
{extract from conversation}

### What it actually was
{extract from conversation}

### How it got fixed
{extract from conversation}

### What wasted time
{extract from conversation}

### How to spot this faster next time
{extract from conversation}
```

### design

```
### Problem being solved
{extract from conversation}

### Options considered
{extract from conversation}

### Trade-offs
{extract from conversation}

### What shaped the final direction
{extract from conversation}

### Open questions
{extract from conversation}
```

### research

```
### What I was trying to understand
{extract from conversation}

### Key discoveries
{extract from conversation}

### Tools / docs / resources found
{extract from conversation}

### What surprised me
{extract from conversation}

### Pros / cons / gotchas
{extract from conversation}

### Would I use this again?
{extract from conversation}
```

### implementation

```
### What was built
{extract from conversation}

### What saved time
{extract from conversation}

### What slowed me down
{extract from conversation}

### What didn't work / was tried and abandoned
{extract from conversation}

### Anything reusable here?
{extract from conversation}
```

### other

```
### What happened
{extract from conversation}

### Worth revisiting?
{extract from conversation}
```

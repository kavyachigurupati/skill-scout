---
name: recall
description: Summarises Claude Code sessions by intent and writes structured notes into Obsidian. Use when asked to summarise, recall, or log sessions from today, yesterday, this week, or a specific date.
allowed-tools: Read, Write, Bash(find *), Bash(ls *), Bash(date *), Bash(head *), Bash(tail *), Bash(cat *), Bash(mkdir *), Bash(wc *), Bash(grep *), Bash(awk *), Bash(sed *), Bash(sort *)
argument-hint: [today|yesterday|this week|last week|YYYY-MM-DD]
---

You summarise Claude Code sessions for a given time range and write structured notes into Obsidian.

**Rules:**
- Never delete files
- Never overwrite existing file content
- Append to log files
- Update state files in place (they reflect current reality, not history)

## Status reporting

At every step, print what you are doing so the user can see progress. If anything fails, print clearly:
- `✓` for success
- `✗ ERROR:` followed by what failed and why
- `⚠ WARNING:` for non-fatal issues (e.g. session skipped, file already exists)

At the end always print a summary block even if nothing was processed.

## Time range

The user passed: $ARGUMENTS

Parse it as:

- `today` → sessions from today
- `yesterday` → sessions from yesterday
- `this week` → last 7 days
- `last week` → the week before this one
- `YYYY-MM-DD` → that specific date
- no argument → default to today

## Step 1 — Check last processed timestamp

Print: `→ Checking ~/Recall/.processed...`

Read `~/Recall/.processed` if it exists. It contains a single ISO timestamp like `2026-04-11T18:00:23`.

- If found → print `  Last run: {timestamp}. Will only process sessions after this.`
- If not found → print `  No .processed file — first run, processing full range.`
- If user explicitly passed a date argument like `this week` or `yesterday` → ignore `.processed`, print `  Explicit range passed — ignoring .processed, processing full range.`

If the file exists but is unreadable → print `✗ ERROR: Could not read ~/Recall/.processed — {reason}. Aborting.` and stop.

## Step 2 — Find sessions

Print: `→ Searching ~/.claude/projects for sessions in range...`

Use `find ~/.claude/projects -name "*.jsonl"` excluding subagent files.

Filter by internal timestamps. Use `head -c 3000` on each file to read the opening — the `ai-title` and first user message are enough to classify intent and project name.

- If no sessions found → print `  ⚠ No sessions found for this time range. Nothing to process.` then print the summary block and stop.
- If sessions found → print `  Found {n} sessions to process.`
- If a session file can't be read → print `  ⚠ WARNING: Could not read {filename} — skipping.`

## Step 3 — Classify each session

Print: `→ Classifying sessions...`

For each session print: `  {filename} → {intent} → {project}`

Pick the single best intent:

- `decisions` — choosing between approaches, tools, or directions
- `bug-fixes` — diagnosing and fixing something broken
- `design` — planning architecture, structure, or system design
- `research` — exploring a tool, library, concept, or approach
- `implementation` — building or writing something concrete
- `other` — anything that doesn't fit above

For the project name — the folder under `~/.claude/projects/` is a mangled path like `-Users-kavya-Desktop-my-project`. Use the last meaningful segment.

## Step 4 — Write two files per project

Print: `→ Writing to ~/Recall/Projects/...`

For each project, maintain two files:

---

### File A: `~/Recall/Projects/{project-name}/{project-name}-log.md`

Append only. Never overwrite.

Each entry uses `{topic}-{intent}` heading (e.g. `skill-scout-design`, `tavily-search-research`). Topic is inferred from session content.

```
# {topic}-{intent}

## {session title} — {date}
**Session:** {session filename}

{fill the matching intent template below}

---
```

On success print: `  ✓ Appended to {project-name}-log.md`
On failure print: `  ✗ ERROR: Could not write {project-name}-log.md — {reason}`

---

### File B: `~/Recall/Projects/{project-name}/{project-name}-state.md`

Living document — read first if exists, update in place. Create if not.

```
# {project-name}

## What it is
{one paragraph}

## Current state
{what is built and working}

## Components / skills / scripts
{list each with one-line description}

## Key decisions
{bullet list, most recent first}

## What has been tried and didn't work
{bullet list}

## Open questions
{unresolved questions}

## Last updated
{date}
```

On success print: `  ✓ Updated {project-name}-state.md`
On failure print: `  ✗ ERROR: Could not write {project-name}-state.md — {reason}`

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

## Step 5 — Update processed timestamp

On success, write current timestamp to `~/Recall/.processed`.
Print: `  ✓ Updated ~/Recall/.processed`

Append to `~/Recall/schedule.log`:
```
[{timestamp}] recall: processed {n} sessions, updated {n} files
```
Print: `  ✓ Logged to ~/Recall/schedule.log`

If either write fails, print the error but do not abort — the notes are already written.

## Step 6 — Print summary

Always print this block, even if nothing was processed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
recall complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Time range : {range}
Sessions   : {n} processed, {n} skipped
Files      : {list of files written}
Next run   : picks up sessions after {timestamp}
Errors     : {n} — {list if any, else "none"}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

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

Read `~/Recall/.processed` if it exists. It contains a single ISO timestamp line like `2026-04-11T18:00:23`. This is when recall last ran successfully.

- If the file exists → only process sessions with internal timestamps **after** this timestamp, regardless of the time range argument
- If the file doesn't exist → process all sessions within the requested time range (first run)
- If the user explicitly passes a date argument like `this week` or `yesterday` → ignore `.processed` and process the full requested range (user is intentionally re-running for a past period)

## Step 2 — Find sessions

Use `find ~/.claude/projects -name "*.jsonl"` excluding subagent files.

Filter to files whose internal timestamps fall within the requested time range AND are after the `.processed` timestamp (if applicable). Use `head -c 3000` on each file to read the opening — the `ai-title` field and first user message are enough to classify intent and extract the project name.

## Step 2 — Classify each session

Pick the single best intent:

- `decisions` — choosing between approaches, tools, or directions
- `bug-fixes` — diagnosing and fixing something broken
- `design` — planning architecture, structure, or system design
- `research` — exploring a tool, library, concept, or approach
- `implementation` — building or writing something concrete
- `other` — anything that doesn't fit above

For the project name — the folder under `~/.claude/projects/` is a mangled path like `-Users-kavya-Desktop-my-project`. Use the last meaningful segment as the project name.

## Step 3 — Write two files per project

For each project encountered in the sessions, maintain two files:

---

### File A: `~/Recall/Projects/{project-name}/{project-name}-log.md`

Append only. Never overwrite. This is the full history — what was tried, what didn't work, why decisions were made.

Each entry uses a descriptive filename-style title derived from the session content — `{topic}-{intent}` (e.g. `skill-scout-design`, `obsidian-setup-research`, `tavily-search-implementation`). Topic is inferred from what the session was actually about, not just the project name.

Start with the intent heading if this is the first entry of that type:

```
# {topic}-{intent}

## {session title} — {date}
**Session:** {session filename}

{fill the matching intent template below}

---
```

For subsequent entries, append the new block. Add a new `# {topic}-{intent}` heading if the topic+intent combination hasn't appeared before.

---

### File B: `~/Recall/Projects/{project-name}/{project-name}-state.md`

Living document — always reflects current reality. Read it first if it exists, then update the relevant sections in place. Create it if it doesn't exist.

Structure:
```
# {project-name}

## What it is
{one paragraph description of what the project does}

## Current state
{what is built and working right now}

## Components / skills / scripts
{list each component with a one-line description}

## Key decisions
{bullet list — one line per decision: what was decided and why, most recent first}

## What has been tried and didn't work
{bullet list — things attempted that failed or were ruled out, so Claude doesn't repeat them}

## Open questions
{unresolved questions or next decisions to make}

## Last updated
{date}
```

When updating: rewrite only the sections that changed. Add new decisions to the top of Key decisions. Add failed approaches to "What has been tried". Remove resolved open questions.

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

## Step 4 — Update processed timestamp

After successfully writing all files, update `~/Recall/.processed` with the current timestamp in ISO format (e.g. `2026-04-11T18:05:42`). Overwrite the file — it only ever holds the single most recent timestamp.

Also append a line to `~/Recall/schedule.log`:
```
[{timestamp}] recall: processed {n} sessions, updated {n} files
```

## Step 5 — Print summary

After writing all files, print:

- Time range processed
- Each session: `{filename} → {intent} → {project}`
- Total sessions processed
- Files written to
- Next run will pick up sessions after: {current timestamp}

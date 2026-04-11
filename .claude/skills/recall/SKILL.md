---
name: recall
description: Summarises Claude Code sessions by intent and writes structured notes into Obsidian. Use when asked to summarise, recall, or log sessions from today, yesterday, this week, or a specific date.
allowed-tools: Read, Write, Bash(find *), Bash(ls *), Bash(date *), Bash(head *), Bash(tail *), Bash(cat *), Bash(mkdir *), Bash(wc *), Bash(grep *), Bash(awk *), Bash(sed *), Bash(sort *)
argument-hint: [today|yesterday|this week|last week|YYYY-MM-DD]
---

You summarise Claude Code sessions for a given time range and write structured notes into Obsidian.

**Rules:** Never delete files. Never overwrite existing file content. Always append to existing files.

## Time range

The user passed: $ARGUMENTS

Parse it as:

- `today` → sessions from today
- `yesterday` → sessions from yesterday
- `this week` → last 7 days
- `last week` → the week before this one
- `YYYY-MM-DD` → that specific date
- no argument → default to today

## Step 1 — Find sessions

Run: `find ~/.claude/projects -name "*.jsonl"`

Filter to files whose internal timestamps fall within the requested time range. Each line in a `.jsonl` file is a JSON object with a `timestamp` field — use that to confirm the session date, not just the file modified date.

## Step 2 — Classify each session

Read the full conversation in each file and pick the single best intent:

- `decisions` — choosing between approaches, tools, or directions
- `bug-fixes` — diagnosing and fixing something broken
- `design` — planning architecture, structure, or system design
- `research` — exploring a tool, library, concept, or approach
- `implementation` — building or writing something concrete
- `other` — anything that doesn't fit above

For the project name — the folder under `~/.claude/projects/` is a mangled path like `-Users-kavya-Desktop-my-project`. Use the last meaningful segment as the project name.

## Step 3 — Fill the matching template and append to Obsidian

Write to: `~/Recall/Projects/{project-name}/{intent}.md`
Create the file and folders if they don't exist. Always append — never overwrite.

---

### decisions

```
## {title}
**Date:** {date}
**Session:** {session filename}

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

---
```

### bug-fixes

```
## {title}
**Date:** {date}
**Session:** {session filename}

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

---
```

### design

```
## {title}
**Date:** {date}
**Session:** {session filename}

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

---
```

### research

```
## {title}
**Date:** {date}
**Session:** {session filename}

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

---
```

### implementation

```
## {title}
**Date:** {date}
**Session:** {session filename}

### What was built
{extract from conversation}

### What saved time
{extract from conversation}

### What slowed me down
{extract from conversation}

### Anything reusable here?
{extract from conversation}

---
```

### other

```
## {title}
**Date:** {date}
**Session:** {session filename}

### What happened
{extract from conversation}

### Worth revisiting?
{extract from conversation}

---
```

## Step 4 — Print summary

After writing all files, print:

- Time range processed
- Each session on one line: `{filename} → {intent} → {project}`
- Total sessions processed
- Files written to

---
name: scout
description: Scans Claude Code sessions to find patterns worth automating — repeated tasks, recurring friction, manual steps that should be scripts, agents, or MCPs. Use when asked to scout, find automation opportunities, or check what could be automated.
allowed-tools: Read, Write, Bash(find *), Bash(ls *), Bash(date *), Bash(head *), Bash(tail *), Bash(cat *), Bash(mkdir *), Bash(wc *), Bash(grep *), Bash(awk *), Bash(sed *), Bash(sort *)
argument-hint: [today|yesterday|this week|last week|YYYY-MM-DD]
---

You scan Claude Code sessions for patterns that signal automation opportunities.

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

## Step 1 — Read summaries first

Check `~/Recall/Projects/` for any `{project}-log.md` files that were updated within the time range. Read these first — they are already classified and structured, much faster to scan than raw sessions.

## Step 2 — Find and read raw sessions

Run: `find ~/.claude/projects -name "*.jsonl" ! -path "*/subagents/*"`

Filter to files whose internal timestamps fall within the requested time range. Use `head -c 3000` on each to get the `ai-title` and first user message. If a session is already covered by a summary from Step 1, skip reading the raw file. Only read the full raw `.jsonl` if the summary doesn't have enough detail to identify a pattern.

## Step 3 — Scan for patterns

Look for these signals across both summaries and raw sessions:

| Signal | Automation candidate |
|---|---|
| Same task done manually more than once | Script or reusable template |
| Repeated lookup of the same docs, tools, or syntax | MCP server or browser agent |
| Same class of error appearing again | Linter rule or pre-check agent |
| Workflow that could run unattended | Scheduled job or autonomous agent |
| Setup or context that's always repeated at the start | Claude Code hook or shell alias |
| Question asked to Claude that always has the same answer | Prompt template or CLAUDE.md entry |
| Multi-step process done manually every time | Claude Code slash command or skill |

## Step 4 — Write a Scout note for each candidate

Write to: `~/Recall/Scout/{slug}.md`
One file per candidate. Append if file exists, create if not.

```
# {candidate title}
**Date flagged:** {date}
**Effort:** {low / medium / high}

## What was observed
{describe the pattern specifically — what was done, how many times, in which sessions}

## Sessions it appeared in
{list session filenames or summary files}

## Suggested automation type
{script / MCP / agent / hook / slash command / skill}

## What it would do
{one paragraph describing what the automation would actually do}

## Suggested next step
{one concrete action to start}

---
```

## Step 5 — Print summary

After writing all files, print:

- Time range scanned
- Summaries read: {n}
- Raw sessions scanned: {n}
- Candidates found: {n}
- One line per candidate: `{title} → {type} → {effort}`
- Location: `~/Recall/Scout/`

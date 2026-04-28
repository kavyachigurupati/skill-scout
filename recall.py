#!/usr/bin/env python3
"""
recall.py — runs the /recall skill non-interactively via the Claude Agent SDK.
Uses your existing Claude Code subscription. No API key required.

Usage:
    python3 recall.py [today|yesterday|this week|last week|YYYY-MM-DD]

Runs unattended — no permission popups.
"""

import asyncio
import sys
from pathlib import Path

try:
    from claude_code_sdk import query, ClaudeCodeOptions
except ImportError:
    print("ERROR: claude-code SDK not installed. Run: pip install claude-code")
    sys.exit(1)


# ── prompt ──────────────────────────────────────────────────────────────────

SKILL_PROMPT = """
You summarise Claude Code sessions for a given time range and write structured notes into Obsidian.

Rules:
- Never delete files
- Never overwrite existing file content
- Append to log files
- Update state files in place (they reflect current reality, not history)

Status reporting — print at every step:
- ✓ for success
- ✗ ERROR: followed by what failed and why
- ⚠ WARNING: for non-fatal issues

Always print a summary block at the end even if nothing was processed.

## Time range

The user passed: {time_range}

- today → sessions from today
- yesterday → sessions from yesterday
- this week → last 7 days
- last week → the week before this one
- YYYY-MM-DD → that specific date
- no argument → default to today

## Step 1 — Check last processed timestamp

Print: → Checking ~/Recall/.processed...

Read ~/Recall/.processed if it exists. It contains a single ISO timestamp like 2026-04-11T18:00:23.

- If found → print "Last run: {{timestamp}}. Will only process sessions after this."
- If not found → print "No .processed file — first run, processing full range."
- If user explicitly passed a date argument like "this week" or "yesterday" → ignore .processed

## Step 2 — Find sessions

Print: → Searching ~/.claude/projects for sessions in range...

Use find ~/.claude/projects -name "*.jsonl" excluding subagent files (! -path "*/subagents/*").

Filter by internal timestamps in each file. Use head -c 3000 on each to read the opening —
the ai-title field and first user message are enough to classify intent and project name.

- If no sessions found → print warning, then print summary block and stop.
- If sessions found → print "Found {{n}} sessions to process."

## Step 3 — Classify each session

Print: → Classifying sessions...

For each session print: {{filename}} → {{intent}} → {{project}}

Pick the single best intent:
- decisions — choosing between approaches, tools, or directions
- bug-fixes — diagnosing and fixing something broken
- design — planning architecture, structure, or system design
- research — exploring a tool, library, concept, or approach
- implementation — building or writing something concrete
- other — anything that doesn't fit above

For the project name — the folder under ~/.claude/projects/ is a mangled path like
-Users-kavya-Desktop-my-project. Use the last meaningful segment.

## Step 4 — Write two files per project

Print: → Writing to ~/Recall/Projects/...

For each project, maintain two files:

### File A: ~/Recall/Projects/{{project-name}}/{{project-name}}-log.md
Append only. Never overwrite.

Each entry:
# {{topic}}-{{intent}}
## {{session title}} — {{date}}
**Session:** {{session filename}}
{{intent-specific content below}}
---

### File B: ~/Recall/Projects/{{project-name}}/{{project-name}}-state.md
Living document — read first if exists, update in place. Create if not.

Structure:
# {{project-name}}
## What it is
## Current state
## Components / skills / scripts
## Key decisions (most recent first)
## What has been tried and didn't work
## Open questions
## Last updated

## Intent templates (for log file)

### decisions
- What was the choice between?
- Why this path was chosen
- What was ruled out and why
- Assumptions being made
- When to revisit

### bug-fixes
- Symptom
- First guess
- What it actually was
- How it got fixed
- What wasted time
- How to spot this faster next time

### design
- Problem being solved
- Options considered
- Trade-offs
- What shaped the final direction
- Open questions

### research
- What I was trying to understand
- Key discoveries
- Tools / docs / resources found
- What surprised me
- Pros / cons / gotchas
- Would I use this again?

### implementation
- What was built
- What saved time
- What slowed me down
- What didn't work / was tried and abandoned
- Anything reusable here?

### other
- What happened
- Worth revisiting?

## Step 5 — Update processed timestamp

Write current ISO timestamp to ~/Recall/.processed (overwrite — single timestamp only).
Append to ~/Recall/schedule.log:
[{{timestamp}}] recall: processed {{n}} sessions, updated {{n}} files

## Step 6 — Print summary

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
recall complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Time range : {{range}}
Sessions   : {{n}} processed, {{n}} skipped
Files      : {{list of files written}}
Next run   : picks up sessions after {{timestamp}}
Errors     : {{n}} — {{list if any, else "none"}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""


# ── main ────────────────────────────────────────────────────────────────────

async def run_recall(time_range: str) -> None:
    prompt = SKILL_PROMPT.format(time_range=time_range)

    options = ClaudeCodeOptions(
        cwd=str(Path.home()),
        allowed_tools=["Read", "Write", "Glob", "Grep", "Bash"],
        permission_mode="bypassPermissions",
        max_turns=40,
    )

    async for message in query(prompt=prompt, options=options):
        # Print assistant text as it streams
        if hasattr(message, "content"):
            for block in message.content:
                if hasattr(block, "text"):
                    print(block.text, end="", flush=True)
        # ResultMessage has a final result field
        elif hasattr(message, "result"):
            if message.result:
                print(message.result, flush=True)


def main() -> None:
    time_range = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "today"
    valid = {"today", "yesterday", "this week", "last week"}
    if time_range not in valid and not (len(time_range) == 10 and time_range[4] == "-"):
        print(f"Usage: python3 recall.py [today|yesterday|this week|last week|YYYY-MM-DD]")
        print(f"Got: '{time_range}'")
        sys.exit(1)

    print(f"Running recall for: {time_range}\n")
    asyncio.run(run_recall(time_range))


if __name__ == "__main__":
    main()

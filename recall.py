#!/usr/bin/env python3
"""
recall.py
---------
Headless runner for the /recall skill. Called by schedule.sh every night.

What it does:
  - Reads .claude/skills/recall/SKILL.md (the skill definition)
  - Sends it to Claude via the Agent SDK with bypassPermissions
  - Claude runs the full recall logic: finds sessions, classifies them,
    writes project logs and state files into ~/Recall/

Why this exists:
  The /recall skill normally runs inside an interactive Claude Code session.
  This script lets it run unattended via cron — no UI, no permission popups.

Usage:
  python3 recall.py [today|yesterday|this week|last week|YYYY-MM-DD]
  Defaults to "today" if no argument given.

Requirements:
  pip install claude-code
  Claude Code must be installed and authenticated.
"""

import asyncio
import sys
from pathlib import Path

try:
    from claude_agent_sdk import query, ClaudeAgentOptions as ClaudeCodeOptions
except ImportError:
    print("ERROR: claude-agent-sdk not installed. Run: pip install claude-agent-sdk")
    sys.exit(1)


SKILL_MD = Path(__file__).parent / ".claude" / "skills" / "recall" / "SKILL.md"


def load_prompt(time_range: str) -> str:
    """Read SKILL.md, strip frontmatter, inject the time range argument."""
    if not SKILL_MD.exists():
        print(f"ERROR: SKILL.md not found at {SKILL_MD}")
        sys.exit(1)

    content = SKILL_MD.read_text()

    # Strip YAML frontmatter (--- ... ---)
    if content.startswith("---"):
        end = content.index("---", 3)
        content = content[end + 3:].strip()

    return content.replace("$ARGUMENTS", time_range)


async def run_recall(time_range: str) -> None:
    prompt = load_prompt(time_range)

    options = ClaudeCodeOptions(
        cwd=str(Path.home()),
        # Skill(*) from SKILL.md is omitted — skills can't be invoked headlessly.
        # schedule.sh calls scout.py explicitly instead.
        allowed_tools=["Read", "Write", "Grep", "Bash"],
        permission_mode="bypassPermissions",
        max_turns=40,
    )

    async for message in query(prompt=prompt, options=options):
        if hasattr(message, "content"):
            for block in message.content:
                if hasattr(block, "text"):
                    print(block.text, end="", flush=True)
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

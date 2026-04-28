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


# ── load skill prompt from SKILL.md ─────────────────────────────────────────

SKILL_MD = Path(__file__).parent / ".claude" / "skills" / "recall" / "SKILL.md"

def load_prompt(time_range: str) -> str:
    if not SKILL_MD.exists():
        print(f"ERROR: SKILL.md not found at {SKILL_MD}")
        sys.exit(1)

    content = SKILL_MD.read_text()

    # Strip frontmatter (--- ... ---)
    if content.startswith("---"):
        end = content.index("---", 3)
        content = content[end + 3:].strip()

    # Inject the time range argument
    return content.replace("$ARGUMENTS", time_range)


# ── main ────────────────────────────────────────────────────────────────────

async def run_recall(time_range: str) -> None:
    prompt = load_prompt(time_range)

    options = ClaudeCodeOptions(
        cwd=str(Path.home()),
        allowed_tools=["Read", "Write", "Glob", "Grep", "Bash"],
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

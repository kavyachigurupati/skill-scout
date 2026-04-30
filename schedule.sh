#!/bin/bash
# schedule.sh
# -----------
# Nightly cron job — installed by setup.sh, runs daily at 6pm.
# DO NOT run this manually unless testing.
#
# What it does:
#   1. Checks if any new Claude Code sessions exist today
#   2. If none → exits silently (no work to do)
#   3. If found → runs recall.py then scout.py headlessly
#
# Why both recall and scout:
#   recall's adaptive scout trigger (Step 10) uses Skill(*) which can't
#   fire headlessly via the Agent SDK — so scout is called explicitly here.
#
# All output is appended to ~/Recall/schedule.log.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/Recall/schedule.log"
PROJECTS_DIR="$HOME/.claude/projects"
TODAY=$(date +%Y-%m-%d)

echo "" >> "$LOG"
echo "[$TODAY $(date +%H:%M)] schedule.sh fired" >> "$LOG"

# Check for .jsonl files modified today (subagents excluded — they are
# fragments of parent sessions and contain no meaningful user content)
NEW_SESSIONS=$(find "$PROJECTS_DIR" -name "*.jsonl" ! -path "*/subagents/*" \
    -newer "$PROJECTS_DIR" 2>/dev/null | head -1)

if [ -z "$NEW_SESSIONS" ]; then
    echo "[$TODAY $(date +%H:%M)] No new sessions today — skipping" >> "$LOG"
    exit 0
fi

echo "[$TODAY $(date +%H:%M)] Sessions found — running recall then scout" >> "$LOG"

python3 "$REPO_DIR/recall.py" today >> "$LOG" 2>&1
echo "[$TODAY $(date +%H:%M)] recall done" >> "$LOG"

python3 "$REPO_DIR/scout.py" today >> "$LOG" 2>&1
echo "[$TODAY $(date +%H:%M)] scout done" >> "$LOG"

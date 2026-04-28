#!/bin/bash
# schedule.sh — nightly cron job for skill-scout
# Installed by setup.sh — runs daily at 6pm

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/Recall/schedule.log"
PROJECTS_DIR="$HOME/.claude/projects"
TODAY=$(date +%Y-%m-%d)

echo "[$TODAY $(date +%H:%M)] schedule.sh fired" >> "$LOG"

# Check for .jsonl files modified today (excluding subagents)
NEW_SESSIONS=$(find "$PROJECTS_DIR" -name "*.jsonl" ! -path "*/subagents/*" -newer "$PROJECTS_DIR" 2>/dev/null | head -1)

if [ -z "$NEW_SESSIONS" ]; then
    echo "[$TODAY $(date +%H:%M)] No new sessions today — exiting" >> "$LOG"
    exit 0
fi

echo "[$TODAY $(date +%H:%M)] Sessions found — running recall then scout" >> "$LOG"

# Run recall (bypassPermissions — no popups)
python3 "$REPO_DIR/recall.py" today >> "$LOG" 2>&1
echo "[$TODAY $(date +%H:%M)] recall done" >> "$LOG"

# Run scout (adaptive trigger in recall can't fire headlessly — run explicitly)
python3 "$REPO_DIR/scout.py" today >> "$LOG" 2>&1
echo "[$TODAY $(date +%H:%M)] scout done" >> "$LOG"

#!/bin/bash
# schedule.sh — runs /recall today and /scout today if new sessions exist
# Installed as a cron job by setup.sh — do not run manually unless testing

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$REPO_DIR/schedule.log"
PROJECTS_DIR="$HOME/.claude/projects"
TODAY=$(date +%Y-%m-%d)

echo "[$TODAY $(date +%H:%M)] schedule.sh fired" >> "$LOG"

# Check for .jsonl files modified today (excluding subagents)
NEW_SESSIONS=$(find "$PROJECTS_DIR" -name "*.jsonl" ! -path "*/subagents/*" -newer "$PROJECTS_DIR" 2>/dev/null | head -1)

if [ -z "$NEW_SESSIONS" ]; then
  echo "[$TODAY $(date +%H:%M)] No new sessions found, exiting" >> "$LOG"
  exit 0
fi

echo "[$TODAY $(date +%H:%M)] Sessions found, running recall.py" >> "$LOG"

# Run recall (uses bypassPermissions — no popups)
python3 "$REPO_DIR/recall.py" today >> "$LOG" 2>&1
echo "[$TODAY $(date +%H:%M)] recall done" >> "$LOG"

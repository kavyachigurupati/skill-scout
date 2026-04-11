#!/bin/bash
# One-time setup for skill-scout
# Run once: bash setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "→ Creating Obsidian vault folders at ~/Recall..."
mkdir -p ~/Recall/Scout
mkdir -p ~/Recall/Projects
mkdir -p ~/Recall/Daily\ Log
echo "  ✓ done"

echo ""
echo "→ Making schedule.sh executable..."
chmod +x "$SCRIPT_DIR/schedule.sh"
echo "  ✓ done"

echo ""
echo "→ Installing cron job (runs daily at 6pm)..."
CRON_JOB="0 18 * * * $SCRIPT_DIR/schedule.sh"
# Add only if not already installed
( crontab -l 2>/dev/null | grep -v "schedule.sh"; echo "$CRON_JOB" ) | crontab -
echo "  ✓ done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete. Next steps:"
echo ""
echo "1. Open Obsidian → open vault → point at ~/Recall"
echo ""
echo "2. /recall and /scout will run automatically at 6pm daily"
echo "   Or trigger manually in Claude Code:"
echo "   /recall today"
echo "   /scout today"
echo ""
echo "3. Check logs at ~/Recall/schedule.log"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
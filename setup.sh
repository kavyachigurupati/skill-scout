#!/bin/bash
# setup.sh — one-time setup for skill-scout
# Run once: bash setup.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "skill-scout setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Python dependency ──────────────────────────────────────────────────────
echo "→ Checking claude-code SDK..."
if python3 -c "import claude_code_sdk" 2>/dev/null; then
    echo "  ✓ already installed"
else
    echo "  Installing..."
    pip install claude-code
    echo "  ✓ installed"
fi

# ── 2. Vault folders ──────────────────────────────────────────────────────────
echo ""
echo "→ Creating ~/Recall vault folders..."
for dir in ~/Recall ~/Recall/Projects ~/Recall/Scout; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir already exists"
    else
        mkdir -p "$dir"
        echo "  ✓ created $dir"
    fi
done

# ── 3. Global skill install ───────────────────────────────────────────────────
echo ""
echo "→ Installing skills to ~/.claude/skills/..."
for skill in recall scout recall-lint; do
    dest="$HOME/.claude/skills/$skill"
    src="$SCRIPT_DIR/.claude/skills/$skill/SKILL.md"
    if [ ! -f "$src" ]; then
        echo "  ⚠ WARNING: $src not found — skipping $skill"
        continue
    fi
    if [ -d "$dest" ]; then
        echo "  ✓ ~/.claude/skills/$skill already exists — updating SKILL.md"
    else
        mkdir -p "$dest"
    fi
    cp "$src" "$dest/SKILL.md"
    echo "  ✓ installed $skill"
done

# ── 4. Make scripts executable ────────────────────────────────────────────────
echo ""
echo "→ Making scripts executable..."
chmod +x "$SCRIPT_DIR/schedule.sh"
chmod +x "$SCRIPT_DIR/recall.py"
echo "  ✓ done"

# ── 5. Cron job ───────────────────────────────────────────────────────────────
echo ""
echo "→ Installing cron job (runs daily at 6pm)..."
CRON_JOB="0 18 * * * $SCRIPT_DIR/schedule.sh"
if crontab -l 2>/dev/null | grep -q "schedule.sh"; then
    echo "  ✓ cron job already installed"
else
    ( crontab -l 2>/dev/null; echo "$CRON_JOB" ) | crontab -
    echo "  ✓ installed: $CRON_JOB"
fi

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete."
echo ""
echo "  /recall, /scout, /recall-lint are ready in Claude Code"
echo "  Cron runs recall.py automatically at 6pm daily"
echo "  Logs at ~/Recall/schedule.log"
echo ""
echo "  NOTE: For cron to access ~/.claude/projects/, grant"
echo "  Terminal Full Disk Access in:"
echo "  System Settings → Privacy & Security → Full Disk Access"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

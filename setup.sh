#!/bin/bash
# setup.sh
# --------
# One-time setup for skill-scout. Run once after cloning, never again.
#
# What it does:
#   1. Installs the claude-code Python SDK (needed by recall.py and scout.py)
#   2. Creates the ~/Recall/ vault folder structure
#   3. Copies the three skills to ~/.claude/skills/ (makes them available in Claude Code)
#   4. Makes recall.py, scout.py, schedule.sh executable
#   5. Installs a cron job that runs schedule.sh daily at 6pm
#
# After this runs:
#   - /recall, /scout, /recall-lint work in any Claude Code session
#   - recall.py and scout.py run automatically every night at 6pm via cron
#
# NOTE: For cron to access ~/.claude/projects/, grant Terminal Full Disk Access:
#   System Settings → Privacy & Security → Full Disk Access → add Terminal

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "skill-scout setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Python SDK ─────────────────────────────────────────────────────────────
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

# ── 3. Install skills globally ────────────────────────────────────────────────
echo ""
echo "→ Installing skills to ~/.claude/skills/..."
for skill in recall scout recall-lint; do
    src="$SCRIPT_DIR/.claude/skills/$skill/SKILL.md"
    dest="$HOME/.claude/skills/$skill"
    if [ ! -f "$src" ]; then
        echo "  ⚠ WARNING: $src not found — skipping $skill"
        continue
    fi
    if [ -d "$dest" ]; then
        echo "  ✓ ~/.claude/skills/$skill exists — updating SKILL.md"
    else
        mkdir -p "$dest"
    fi
    cp "$src" "$dest/SKILL.md"
    echo "  ✓ installed $skill"
done

# ── 4. Make scripts executable ────────────────────────────────────────────────
echo ""
echo "→ Making scripts executable..."
chmod +x "$SCRIPT_DIR/schedule.sh" "$SCRIPT_DIR/recall.py" "$SCRIPT_DIR/scout.py"
echo "  ✓ done"

# ── 5. Cron job ───────────────────────────────────────────────────────────────
echo ""
echo "→ Installing cron job (daily at 6pm)..."
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
echo "  Skills available in Claude Code:"
echo "    /recall, /scout, /recall-lint"
echo ""
echo "  Cron job runs automatically at 6pm daily."
echo "  Logs at ~/Recall/schedule.log"
echo ""
echo "  IMPORTANT: Grant Terminal Full Disk Access for cron to work:"
echo "  System Settings → Privacy & Security → Full Disk Access"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

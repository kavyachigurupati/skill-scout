#!/bin/bash
# One-time setup for skill-scout
# Run this once: bash setup.sh

set -e

VAULT="${1:-$HOME/Recall}"

echo "→ Creating Obsidian vault folders at $VAULT ..."
mkdir -p "$VAULT/Scout"
mkdir -p "$VAULT/Daily Log"
echo "  ✓ vault structure created"

echo ""
echo "→ Installing /scout slash command into Claude Code..."
mkdir -p ~/.claude/commands
cp .claude/commands/scout.md ~/.claude/commands/scout.md
echo "  ✓ slash command installed at ~/.claude/commands/scout.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Done. Two things left:"
echo ""
echo "1. Download Obsidian from https://obsidian.md"
echo "   Open vault → point it at: $VAULT"
echo ""
echo "2. In VS Code with Claude Code, type:"
echo "   /scout"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
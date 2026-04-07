#!/bin/bash
# One-time setup for skill-scout
# Run once: bash setup.sh

echo "→ Creating Obsidian vault folders at ~/Recall..."
mkdir -p ~/Recall/Scout
mkdir -p ~/Recall/Projects
mkdir -p ~/Recall/Daily\ Log
echo "  ✓ done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo ""
echo "1. Open Obsidian → open vault → point at ~/Recall"
echo ""
echo "2. Open this project in VS Code with Claude Code"
echo "   then type:"
echo "   /recall today"
echo "   /scout today"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
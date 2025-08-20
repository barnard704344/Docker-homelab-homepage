#!/bin/bash

# Auto-update script that handles git conflicts automatically
# This script ensures clean updates without manual conflict resolution

echo "=== Auto Git Update ==="

echo "Checking for local changes..."
if git diff --quiet && git diff --cached --quiet; then
    echo "✓ No local changes detected"
    git pull
else
    echo "⚠ Local changes detected, handling automatically..."
    
    # Show what would be overwritten
    echo "Files with local changes:"
    git diff --name-only
    git diff --cached --name-only
    
    echo ""
    echo "Auto-resolving conflicts by preferring remote changes..."
    
    # Stash any local changes
    git stash push -m "Auto-stash before update $(date)"
    
    # Pull the updates
    git pull
    
    echo "✓ Update complete. Local changes have been stashed."
    echo "To see stashed changes later: git stash list"
    echo "To restore stashed changes: git stash pop"
fi

echo ""
echo "Current status:"
git status --short

echo ""
echo "✓ Git update complete. Ready to run: bash setup.sh"

#!/bin/bash

# Diagnostic script to understand why files have local modifications
echo "=== Git Modification Diagnostic ==="
echo "Timestamp: $(date)"
echo

echo "=== Files with local changes ==="
git status --porcelain

echo
echo "=== Detailed diff for scan.sh ==="
if git diff --name-only | grep -q "scan.sh"; then
    echo "scan.sh has modifications:"
    git diff scan.sh
    echo
    echo "File info:"
    ls -la scan.sh
    echo "File permissions: $(stat -c '%a' scan.sh 2>/dev/null || stat -f '%A' scan.sh 2>/dev/null)"
else
    echo "scan.sh has no modifications"
fi

echo
echo "=== Detailed diff for start.sh ==="
if git diff --name-only | grep -q "start.sh"; then
    echo "start.sh has modifications:"
    git diff start.sh
    echo
    echo "File info:"
    ls -la start.sh
    echo "File permissions: $(stat -c '%a' start.sh 2>/dev/null || stat -f '%A' start.sh 2>/dev/null)"
else
    echo "start.sh has no modifications"
fi

echo
echo "=== Git configuration ==="
echo "Git autocrlf setting: $(git config core.autocrlf || echo 'not set')"
echo "Git filemode setting: $(git config core.filemode || echo 'not set')"

echo
echo "=== Working directory info ==="
echo "Current user: $(whoami)"
echo "Working directory: $(pwd)"
echo "Git repository root: $(git rev-parse --show-toplevel)"

echo
echo "=== Recent git history ==="
git log --oneline -5

echo
echo "=== Suggestion ==="
echo "If files show only permission or whitespace changes:"
echo "  git config core.filemode false"
echo "  git config core.autocrlf false"
echo "If you want to ignore these changes:"
echo "  git reset --hard HEAD"

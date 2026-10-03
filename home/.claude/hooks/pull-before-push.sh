#!/bin/bash
# Claude Code PreToolUse hook: require pull before push if behind remote

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null)

# Only check git push commands
if ! echo "$COMMAND" | grep -qE 'git push'; then
  exit 0
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -z "$BRANCH" ]; then
  exit 0
fi

# Fetch latest from remote (quiet)
git fetch origin "$BRANCH" --quiet 2>/dev/null

# Check if remote branch exists
if ! git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
  # First push — no remote branch yet, allow
  exit 0
fi

# Count commits we're behind
BEHIND=$(git rev-list --count "HEAD..origin/$BRANCH" 2>/dev/null)

if [ "$BEHIND" -gt 0 ]; then
  echo "Local branch is $BEHIND commit(s) behind origin/$BRANCH." >&2
  echo "Pull first: git pull origin $BRANCH" >&2
  exit 2
fi

exit 0

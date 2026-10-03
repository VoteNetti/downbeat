#!/bin/bash
# Claude Code PreToolUse hook: block commits on main branch

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null)

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git commit'; then
  exit 0
fi

# Check current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ "$BRANCH" = "main" ]; then
  echo "Cannot commit directly to main. Create a feature branch first:" >&2
  echo "  git checkout -b feature/your-feature-name" >&2
  exit 2
fi

exit 0

#!/bin/bash
# Claude Code PreToolUse hook: enforce commit message format
# Requires a [tag] prefix: [chore], [infra], [fix], [docs], [feat]
# Skips merge commits
# NOTE: [spec-NNN] is intentionally excluded — that tag is project-level only.
# Projects using the Software Factory pattern should add their own local hook.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null)

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git commit'; then
  exit 0
fi

# Skip merge commits and amends
if echo "$COMMAND" | grep -qE 'git merge|--no-edit|--amend'; then
  exit 0
fi

# Use Python to extract commit message (handles quotes, heredocs reliably)
MSG=$(echo "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read().strip()
# Check for heredoc pattern first: -m \"\$(cat <<'EOF'...EOF...)\"
heredoc = re.search(r\"cat <<'?EOF'?\s*\\\\n\s*(.+?)\\\\n\", cmd)
if not heredoc:
    heredoc = re.search(r\"cat <<'?EOF'?\n\s*(.+?)\n\", cmd)
if heredoc:
    print(heredoc.group(1).strip())
else:
    # Match -m \"...\" or -m '...'
    m = re.search(r'-m\s+\"([^\"]+)\"', cmd) or re.search(r\"-m\s+'([^']+)'\", cmd)
    if m:
        msg = m.group(1)
        # If it's a heredoc wrapper, skip it
        if '\$(cat' not in msg:
            print(msg)
" 2>/dev/null)

# If we can't extract a message, allow (interactive or complex invocation)
if [ -z "$MSG" ]; then
  exit 0
fi

# Check for valid prefix
if echo "$MSG" | grep -qE '^\[(chore|infra|fix|docs|feat)\]'; then
  exit 0
fi

echo "Commit message must start with a valid tag prefix:" >&2
echo "  [feat]      — new feature" >&2
echo "  [fix]       — bug fixes" >&2
echo "  [chore]     — maintenance, dependencies, cleanup" >&2
echo "  [infra]     — infrastructure, CI/CD, tooling" >&2
echo "  [docs]      — documentation" >&2
echo "" >&2
echo "Got: \"$MSG\"" >&2
exit 2

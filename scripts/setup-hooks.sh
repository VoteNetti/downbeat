#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Setting up development hooks for downbeat..."

# gitleaks comes from the Brewfile
if ! command -v gitleaks &> /dev/null; then
    echo "ERROR: gitleaks is not installed. Run ./install.sh (or: brew install gitleaks) first."
    exit 1
fi

# Install pre-commit hook
HOOKS_DIR="$REPO_DIR/.git/hooks"
mkdir -p "$HOOKS_DIR"

cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/bin/bash
# Pre-commit hook: scan for secrets using gitleaks

if ! command -v gitleaks &> /dev/null; then
    echo "WARNING: gitleaks is not installed. Skipping secret scan."
    echo "Run: ./scripts/setup-hooks.sh to install"
    exit 0
fi

gitleaks protect --staged --config "$(git rev-parse --show-toplevel)/.gitleaks.toml" --verbose
HOOK

chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ Pre-commit hook installed"

echo ""
echo "✅ Development hooks setup complete!"
echo "   Secrets will be scanned on every commit."

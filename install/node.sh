#!/bin/bash
# Install nvm (official installer), the current Node.js LTS, and global npm tools.
# Safe to re-run: picks up a newer LTS and upgrades global tools.

NVM_VERSION="v0.40.8"
NPM_GLOBALS=(aws-cdk)

export NVM_DIR="$HOME/.nvm"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "📦 Installing nvm $NVM_VERSION..."
    # PROFILE=/dev/null stops the installer from editing shell rc files;
    # home/.zshrc loads nvm through the Oh My Zsh nvm plugin.
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
else
    echo "✓ nvm already installed"
fi

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
# Stop here rather than fall through to some other npm on PATH (e.g. Homebrew's).
if ! command -v nvm &> /dev/null; then
    echo "❌ nvm didn't load from $NVM_DIR/nvm.sh (often a leftover Homebrew or older nvm)."
    echo "   Move it aside and re-run to get a fresh copy: mv $NVM_DIR $NVM_DIR.old && ./install.sh"
    exit 1
fi

echo "📦 Installing Node.js LTS..."
nvm install --lts || exit 1
nvm alias default 'lts/*'
nvm use default || exit 1

echo "📦 Installing global npm tools: ${NPM_GLOBALS[*]}"
npm install -g "${NPM_GLOBALS[@]}"

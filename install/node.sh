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

echo "📦 Installing Node.js LTS..."
nvm install --lts
nvm alias default 'lts/*'
nvm use default

echo "📦 Installing global npm tools: ${NPM_GLOBALS[*]}"
npm install -g "${NPM_GLOBALS[@]}"

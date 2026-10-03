#!/bin/bash
# downbeat bootstrap for a new machine:
#   curl -fsSL https://raw.githubusercontent.com/VoteNetti/downbeat/main/bootstrap.sh | bash
#
# Gets git, clones downbeat to $DOWNBEAT_DIR (default ~/.downbeat), then runs install.sh.
# Dotfiles are symlinked into that clone, so keep it where it is afterwards.
set -euo pipefail

DOWNBEAT_DIR="${DOWNBEAT_DIR:-$HOME/.downbeat}"
DOWNBEAT_REPO="${DOWNBEAT_REPO:-https://github.com/VoteNetti/downbeat.git}"

echo "🥁 downbeat bootstrap → $DOWNBEAT_DIR"

# git is the only thing needed before cloning
if ! command -v git &> /dev/null || { [ "$(uname -s)" = "Darwin" ] && ! xcode-select -p &> /dev/null; }; then
    case "$(uname -s)" in
        Darwin)
            # The Homebrew installer installs the Xcode Command Line Tools (which include git)
            echo "📦 Installing Homebrew (brings the Xcode Command Line Tools and git)..."
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
        Linux)
            echo "📦 Installing git..."
            sudo apt-get update && sudo apt-get install -y git
            ;;
    esac
fi

if [ -d "$DOWNBEAT_DIR/.git" ]; then
    echo "✓ Already cloned; updating"
    git -C "$DOWNBEAT_DIR" pull --ff-only
else
    git clone "$DOWNBEAT_REPO" "$DOWNBEAT_DIR"
fi

# stdin is this script when piped from curl; give install.sh the terminal if there is one
if [ -r /dev/tty ] && { : < /dev/tty; } 2> /dev/null; then
    exec "$DOWNBEAT_DIR/install.sh" < /dev/tty
else
    exec "$DOWNBEAT_DIR/install.sh"
fi

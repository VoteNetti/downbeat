#!/bin/bash
# downbeat: Homebrew packages + symlinked dotfiles for macOS and Linux.
# Safe to re-run; re-running is also how you update.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILURES=()

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0"
    echo "  Installs Homebrew and the Brewfile, Oh My Zsh, nvm/Node, and links home/ into \$HOME."
    echo "  Re-run at any time to pick up changes and upgrade packages."
    exit 0
fi

# Run a step, recording failures instead of aborting
step() {
    local name="$1"
    shift
    echo
    echo "▶ $name"
    if ! "$@"; then
        FAILURES+=("$name")
        echo "⚠️  $name failed (continuing)"
    fi
}

install_linux_prereqs() {
    [ "$(uname -s)" = "Linux" ] || return 0
    if ! command -v apt-get &> /dev/null; then
        echo "Not a Debian/Ubuntu system: install build tools, procps, curl, file, git and zsh yourself."
        return 0
    fi
    sudo apt-get update && sudo apt-get install -y build-essential procps curl file git zsh
}

load_brew() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$brew_bin" ]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
    return 1
}

install_homebrew() {
    if load_brew; then
        echo "✓ Homebrew already installed"
        return 0
    fi
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && load_brew
}

# Homebrew refuses to load formulae from third-party taps until they are trusted.
# Trust each tap formula listed in the Brewfile (formula-level, not the whole tap).
trust_brewfile_taps() {
    local formula
    for formula in $(brew bundle list --file="$REPO_DIR/Brewfile" --formula | grep '^[^/]*/[^/]*/'); do
        brew tap "${formula%/*}" && brew trust --formula "$formula" || return 1
    done
}

install_oh_my_zsh() {
    if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        echo "✓ Oh My Zsh already installed (it updates itself)"
        return 0
    fi
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# Symlink every file under home/ to the same path under $HOME.
# Files are linked individually so tool-owned directories (~/.claude, ~/.oh-my-zsh) stay real.
link_dotfiles() {
    local src rel dest
    while IFS= read -r -d '' src; do
        rel="${src#"$REPO_DIR/home/"}"
        dest="$HOME/$rel"
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
            continue
        fi
        mkdir -p "$(dirname "$dest")"
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
            echo "  backed up existing ~/$rel"
        fi
        ln -sfn "$src" "$dest"
        echo "  linked ~/$rel"
    done < <(find "$REPO_DIR/home" -type f ! -name '.DS_Store' -print0)
    echo "✓ Dotfiles linked"
}

# Print the public SSH signing key registered on a GitHub account. The endpoint is public,
# so no login is needed. Messages go to stderr; only the key goes to stdout.
github_signing_key() {
    local github_user="$1" keys count choice
    keys="$(curl -fsSL "https://api.github.com/users/$github_user/ssh_signing_keys")" || {
        echo "  could not reach GitHub to look up signing keys for $github_user" >&2
        return 1
    }
    count="$(jq 'length' <<< "$keys")"
    if [ "$count" -eq 0 ]; then
        echo "  no SSH signing keys registered on GitHub for $github_user" >&2
        return 1
    fi
    choice=1
    if [ "$count" -gt 1 ]; then
        if [ ! -t 0 ]; then
            echo "  $github_user has $count signing keys on GitHub; run install.sh in a terminal to choose" >&2
            return 1
        fi
        jq -r 'to_entries[] | "  \(.key + 1)) \(.value.title)"' <<< "$keys" >&2
        read -r -p "Which signing key? [1-$count]: " choice
    fi
    jq -er --argjson i "$((choice - 1))" '.[$i].key' <<< "$keys" || return 1
    echo "✓ Signing key \"$(jq -r --argjson i "$((choice - 1))" '.[$i].title' <<< "$keys")\" found on GitHub" >&2
}

# Identity and signing key are per person, so they live in ~/.gitconfig.local, never in this repo.
# Each value comes from a DOWNBEAT_* variable, then ~/.gitconfig.local, then a prompt.
# Signing is on only with a key and 1Password's signer; otherwise it's turned off for this machine.
configure_git_identity() {
    local local_config="$HOME/.gitconfig.local"
    local name email key github_user="${DOWNBEAT_GITHUB_USER:-}" signer="" candidate
    name="$(git config --file "$local_config" user.name)"
    email="${DOWNBEAT_GIT_EMAIL:-$(git config --file "$local_config" user.email)}"
    key="$(git config --file "$local_config" user.signingkey)"

    if { [ -z "$name" ] || [ -z "$key" ]; } && [ -z "$github_user" ] && [ -t 0 ]; then
        read -r -p "GitHub username: " github_user
    fi
    name="${name:-$github_user}"
    if [ -z "$email" ] && [ -t 0 ]; then
        read -r -p "Git email (one verified on your GitHub account): " email
    fi
    [ -n "$name" ] && git config --file "$local_config" user.name "$name"
    [ -n "$email" ] && git config --file "$local_config" user.email "$email"
    if [ -z "$name" ] || [ -z "$email" ]; then
        echo "⚠️  Git identity not set. Re-run install.sh in a terminal, or set DOWNBEAT_GITHUB_USER and DOWNBEAT_GIT_EMAIL."
    fi

    if [ -z "$key" ] && [ -n "$github_user" ] && key="$(github_signing_key "$github_user")"; then
        git config --file "$local_config" user.signingkey "key::$key"
    fi

    for candidate in "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" /opt/1Password/op-ssh-sign; do
        [ -x "$candidate" ] && signer="$candidate" && break
    done

    if [ -n "$key" ] && [ -n "$email" ] && [ -n "$signer" ]; then
        git config --file "$local_config" gpg.ssh.program "$signer"
        git config --file "$local_config" --unset commit.gpgsign
        git config --file "$local_config" --unset tag.gpgsign
        # Lets `git log --show-signature` verify my own commits locally
        mkdir -p "$HOME/.config/git"
        rm -f "$HOME/.config/git/allowed_signers"
        printf '%s namespaces="git" %s\n' "$email" "${key#key::}" > "$HOME/.config/git/allowed_signers"
        echo "✓ Commits and tags signed with 1Password ($signer)"
    else
        git config --file "$local_config" commit.gpgsign false
        git config --file "$local_config" tag.gpgsign false
        [ -z "$key" ] && echo "⚠️  No signing key: signing turned off on this machine (in ~/.gitconfig.local)"
        [ -n "$key" ] && [ -z "$signer" ] && echo "⚠️  1Password op-ssh-sign not found: signing turned off on this machine (in ~/.gitconfig.local)"
        [ -n "$key" ] && [ -n "$signer" ] && echo "⚠️  No git email: signing turned off on this machine (in ~/.gitconfig.local)"
    fi
    return 0
}

# Claude Code writes to settings.json itself, so it is merged rather than symlinked
merge_claude_settings() {
    local settings="$HOME/.claude/settings.json" merged
    mkdir -p "$HOME/.claude"
    [ -s "$settings" ] || echo '{}' > "$settings"
    merged="$(jq -s -f "$REPO_DIR/claude/merge-settings.jq" "$settings" "$REPO_DIR/claude/settings.base.json")" || return 1
    printf '%s\n' "$merged" > "$settings"
    echo "✓ Claude settings merged"
}

# pre-commit hooks for this repo (gitleaks + shellcheck): dotfiles are symlinked here, so
# anything a tool appends to ~/.zshrc (API keys included) would otherwise be one commit
# away from GitHub. -f replaces the old hand-written hook.
install_repo_hooks() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "⏭️  Not a git checkout: skipping repo hooks"
        return 0
    fi
    (cd "$REPO_DIR" && pre-commit install -f --install-hooks)
}

change_default_shell() {
    if [ -f /.dockerenv ] || [ -n "${CI:-}" ]; then
        echo "⏭️  Docker/CI detected: not changing shell (run zsh manually)"
        return 0
    fi
    local zsh_path
    zsh_path="$(grep -m1 '/zsh$' /etc/shells)"
    if [ -z "$zsh_path" ]; then
        echo "zsh is not listed in /etc/shells"
        return 1
    fi
    if [ "$SHELL" = "$zsh_path" ]; then
        echo "✓ zsh is already the default shell"
        return 0
    fi
    chsh -s "$zsh_path" && echo "✓ Default shell changed to zsh (restart your terminal)"
}

echo "🥁 downbeat ($(uname -s))"

step "Linux prerequisites" install_linux_prereqs
step "Homebrew" install_homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is required for everything else. Fix the error above and re-run."
    exit 1
fi
step "Trust tap formulae" trust_brewfile_taps
step "Brewfile packages" brew bundle --file="$REPO_DIR/Brewfile"
step "Oh My Zsh" install_oh_my_zsh
step "Dotfiles" link_dotfiles
step "Git identity and signing" configure_git_identity
step "Repo hooks (pre-commit)" install_repo_hooks
step "Claude settings" merge_claude_settings
step "Node.js (nvm)" bash "$REPO_DIR/install/node.sh"
step "Default shell" change_default_shell

echo
if ! gh auth status &> /dev/null; then
    echo "🔑 GitHub CLI is not logged in. To push changes to downbeat, run:"
    echo "     gh auth login && gh auth setup-git"
    echo
fi
if [ ${#FAILURES[@]} -gt 0 ]; then
    echo "⚠️  Finished with issues in:"
    printf '   - %s\n' "${FAILURES[@]}"
    echo "   Re-run ./install.sh to retry."
    exit 1
fi
echo "✅ Done. Put machine-specific settings in ~/.zshrc.local and ~/.zprofile.local."
echo "   To see installed packages that aren't in the Brewfile: brew bundle cleanup --file=$REPO_DIR/Brewfile"

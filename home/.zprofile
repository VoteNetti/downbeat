# Managed by downbeat (symlinked from home/.zprofile).
# Machine-specific settings belong in ~/.zprofile.local, which is not tracked.

for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
        eval "$("$brew_bin" shellenv)"
        break
    fi
done
unset brew_bin

[[ -f "$HOME/.zprofile.local" ]] && source "$HOME/.zprofile.local"

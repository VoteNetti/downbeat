# Managed by downbeat (symlinked from home/.zshrc).
# Machine-specific settings belong in ~/.zshrc.local, which is not tracked.

# Login shells get Homebrew from ~/.zprofile; cover non-login shells too (e.g. Linux terminals)
[[ -z "$HOMEBREW_PREFIX" && -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"

# nvm is loaded on first use of node/npm/etc. to keep startup fast
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd cdk

plugins=(git netti-git history brew nmap 1password vscode aws terraform nvm zsh-interactive-cd)

source "$ZSH/oh-my-zsh.sh"

command -v fzf &> /dev/null && source <(fzf --zsh)

alias wmip="curl checkip.amazonaws.com"
alias dv="dirs -v"

# Caller identity plus account name, for the default or a given profile: awswami [profile]
awswami() {
    local args=() ident name
    [[ -n "$1" ]] && args=(--profile "$1")
    ident="$(aws "${args[@]}" sts get-caller-identity)" || return
    name="$(aws "${args[@]}" account get-account-information --query AccountName --output text 2>/dev/null)"
    jq -S --arg name "$name" '. + {AccountName: $name}' <<< "$ident"
}

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

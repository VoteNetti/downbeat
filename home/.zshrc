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

# Plugins for tools that aren't installed (minimal machines) are left out
plugins=(git netti-git history zsh-interactive-cd)
for tool in brew nmap op:1password code:vscode aws terraform; do
    (( $+commands[${tool%%:*}] )) && plugins+=(${tool##*:})
done
unset tool
[[ -d "${NVM_DIR:-$HOME/.nvm}" ]] && plugins+=(nvm)

source "$ZSH/oh-my-zsh.sh"

if command -v fzf &> /dev/null; then
    if fzf --zsh &> /dev/null; then
        source <(fzf --zsh)
    elif [[ -d /usr/share/doc/fzf/examples ]]; then
        # apt's fzf can predate `fzf --zsh`
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh 2> /dev/null
    fi
fi

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

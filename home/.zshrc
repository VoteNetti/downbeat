# Managed by downbeat (symlinked from home/.zshrc).
# Machine-specific settings belong in ~/.zshrc.local, which is not tracked.

# Login shells get Homebrew from ~/.zprofile; cover non-login shells too (e.g. Linux terminals)
[[ -z "$HOMEBREW_PREFIX" && -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

# SSH forwards the client's LANG, which a minimal server may not have generated; without a UTF-8
# locale the prompt's arrow renders as "?". C.UTF-8 ships with Ubuntu and Debian.
if [[ "$(locale charmap 2> /dev/null)" != UTF-8 ]] && locale -a 2> /dev/null | grep -qix 'C.utf-\?8'; then
    export LANG=C.UTF-8 LC_ALL=C.UTF-8
fi

# SSH forwards the client's TERM (e.g. xterm-ghostty), which a minimal server has no terminfo for;
# zsh then mangles the prompt ("?➜"). Fall back to a TERM every server knows.
if [[ -n "$TERM" ]] && ! infocmp "$TERM" &> /dev/null; then
    export TERM=xterm-256color
fi

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
    else
        # apt's fzf can predate `fzf --zsh`; install.sh --minimal extracts its zsh files when
        # minimized Ubuntu has stripped /usr/share/doc
        for fzf_dir in /usr/share/doc/fzf/examples "$HOME/.local/share/downbeat/fzf"; do
            if [[ -f $fzf_dir/key-bindings.zsh ]]; then
                source "$fzf_dir/key-bindings.zsh"
                [[ -f $fzf_dir/completion.zsh ]] && source "$fzf_dir/completion.zsh"
                break
            fi
        done
        unset fzf_dir
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

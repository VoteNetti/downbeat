# Managed by downbeat (symlinked from home/.zshrc).
# Machine-specific settings belong in ~/.zshrc.local, which is not tracked.

# Login shells get Homebrew from ~/.zprofile; cover non-login shells too (e.g. Linux terminals)
[[ -z "$HOMEBREW_PREFIX" && -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# nvm is loaded on first use of node/npm/etc. to keep startup fast
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd cdk

plugins=(git netti-git history brew nmap 1password vscode aws terraform nvm zsh-interactive-cd)

source "$ZSH/oh-my-zsh.sh"

command -v fzf &> /dev/null && source <(fzf --zsh)

alias wmip="curl checkip.amazonaws.com"
alias dv="dirs -v"
alias awswami="aws sts get-caller-identity"

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

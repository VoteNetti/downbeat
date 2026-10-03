# My packages for downbeat: the tools I want on every machine.
# `brew bundle` installs anything missing and upgrades anything outdated.
# Everything outside `if OS.mac?` must also work with Homebrew on Linux.
#
# Not managed here:
#   - Docker CLI: Docker Desktop (cask below) ships its own `docker` CLI, which conflicts
#     with brew's `docker` / `docker-completion` formulae. Don't add those.
#   - Node.js / nvm / AWS CDK: installed by install/node.sh.

tap "hashicorp/tap"
tap "anomalyco/tap"

# Shell and core CLI
brew "git"
brew "gh"
brew "jq"
brew "wget"
brew "fzf"
brew "neovim"
brew "uv"
brew "nmap"

# Cloud and infrastructure
brew "awscli"
brew "hashicorp/tap/terraform"
brew "kubernetes-cli"
brew "helm"

# Linting and security scanning
brew "cfn-lint"
brew "checkov"
brew "semgrep"
brew "gitleaks"
brew "pre-commit"

# AI tools
brew "anomalyco/tap/opencode"

if OS.mac?
  brew "powershell"

  cask "1password-cli"
  cask "docker-desktop"
  cask "iterm2"
  cask "visual-studio-code"
  cask "sublime-text"
  cask "drawio"
  cask "ollama-app"
end

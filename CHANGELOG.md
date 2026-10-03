# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Secret scanning and shell linting run through the [pre-commit](https://pre-commit.com) framework: `.pre-commit-config.yaml` has gitleaks (with `.gitleaks.toml`) and shellcheck. `install.sh` runs `pre-commit install` and replaces the old hand-written hook

### Removed
- `scripts/setup-hooks.sh`

## [2.0.0] - 2026-10-03

Renamed to **downbeat** and rebuilt around Homebrew on every platform and symlinked dotfiles. Breaking: the install layout, flags and config locations have changed.

### Added
- `bootstrap.sh`: one-line new-machine setup (`curl | bash`) that gets git, clones to `~/.downbeat` and runs `install.sh`
- `install.sh` installs the gitleaks pre-commit hook and reminds you to run `gh auth login` if needed
- `Brewfile` as the single package list (`brew bundle`), with macOS-only casks in an `if OS.mac?` block
- `home/` directory mirroring `$HOME`; every file is symlinked into place, and existing files are backed up to `*.bak.<timestamp>`
- Untracked per-machine overrides: `~/.zshrc.local`, `~/.zprofile.local`, `~/.gitconfig.local`
- `home/.zprofile` that loads Homebrew on Apple Silicon, Intel and Linux
- `install/node.sh`: nvm from the official installer, Node.js LTS, global npm tools (`aws-cdk`)
- `install.sh` trusts the Brewfile's third-party tap formulae (`brew trust --formula`) before `brew bundle`, as newer Homebrew requires
- SSH commit and tag signing through 1Password (`op-ssh-sign`); the public signing key is looked up on GitHub from the username, and `allowed_signers` is generated for local verification. Signing is turned off automatically on machines without 1Password or a key
- Oh My Zsh `nvm` (lazy-loaded) and `terraform` plugins
- `claude/settings.base.json` + `claude/merge-settings.jq` for the Claude Code settings merge

### Changed
- Linux installs packages with Homebrew instead of apt, pip, curl and GitHub release downloads
- `install.sh` rewritten as a single idempotent script; re-running it is how you update
- Git identity is never tracked: `install.sh` asks for a GitHub username and email on the first run (or reads `DOWNBEAT_GITHUB_USER` / `DOWNBEAT_GIT_EMAIL`) and saves them in `~/.gitconfig.local`
- Claude agents, commands and hooks are symlinked instead of copied
- Claude settings merge uses `jq` instead of embedded Python and no longer duplicates hooks
- PowerShell comes from Homebrew core instead of the deprecated `powershell/tap` (macOS only)
- AWS CDK is installed with npm under nvm instead of brew
- `scripts/setup-hooks.sh` expects gitleaks from the Brewfile
- Docker test helper uses `docker compose` instead of `docker-compose`
- GitHub Actions workflows use Node 24 action versions

### Removed
- `--update` flag (re-run `./install.sh` instead)
- `install/macos.sh`, `install/linux.sh`, `install/universal.sh`, `scripts/detect_os.sh`, `scripts/utils.sh`
- `configs/` directory (moved to `home/`)
- VS Code settings and keybindings (use VS Code Settings Sync)
- brew `docker` / `docker-completion` formulae (Docker Desktop's cask provides the CLI)
- `CLAUDE-handoff.md`

### Fixed
- nvm setup no longer appends to `~/.zshrc` on every run
- AWS CDK is no longer reinstalled on every run (the old check looked for an `aws-cdk` command; the real one is `cdk`)

## [1.0.2] - 2026-02-03

### Removed
- Claude alias from ZSH configuration

## [1.0.1] - 2026-01-29

### Fixed
- PowerShell installation on ARM64 Ubuntu (downloads .deb from GitHub releases instead of Microsoft apt repo)

### Changed
- Install scripts continue on non-critical tool failures instead of aborting
- Failed installations are reported in a summary at the end of setup
- Removed `set -e` from install scripts in favor of explicit error handling via `run_install`

## [1.0.0] - 2025-01-29

### Added
- macOS workstation setup (Homebrew, VS Code, Sublime Text, Xcode CLI tools)
- Ubuntu/Linux workstation setup (essential packages, VS Code)
- Universal tool installation (ZSH, Oh My ZSH, Git, Node.js/NVM, AWS CLI/CDK, GitHub CLI, Terraform, PowerShell, wget, fzf)
- Custom ZSH configuration with Oh My ZSH plugins
- Custom Git configuration with interactive identity setup
- VS Code settings and keybindings
- Docker-based testing for Ubuntu
- OS detection (macOS, Ubuntu, Debian, generic Linux)
- Pre-commit secret scanning with gitleaks
- GitHub Actions secret scanning workflow
- GitHub Actions automatic release workflow
- Shared utility functions (`scripts/utils.sh`)
- README documentation

Versions before 2.0.0 were developed as `netti-defaults`; that repository and its history are archived privately.

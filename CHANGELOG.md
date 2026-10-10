# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [3.2.1] - 2026-10-10

### Fixed
- Minimal mode never asks for a git email; it prints a hint to set `DOWNBEAT_GIT_EMAIL` or edit `~/.gitconfig.local` instead
- `.zshrc` falls back to `TERM=xterm-256color` when the client's `TERM` (e.g. `xterm-ghostty`) has no terminfo on the server, which was mangling the prompt
- Minimal mode asks for a git name instead of a GitHub username (there's no key lookup there)
- Minimal mode on minimized Ubuntu: fzf's zsh files are extracted from the apt package when `/usr/share/doc` has been stripped, and `.zshrc` no longer errors when they're missing
- `.zshrc` falls back to `C.UTF-8` when the forwarded locale isn't installed, so the prompt arrow no longer renders as `?`

## [3.2.0] - 2026-10-07

### Added
- Minimal install mode for terminal-only Debian/Ubuntu machines (`install.sh --minimal` or `DOWNBEAT_MODE=minimal`, also through `bootstrap.sh`): zsh and fzf from apt, Oh My Zsh and the shell dotfiles; no Homebrew, GUI config, `downbeat` command, Node or commit signing. The mode is remembered in `~/.config/downbeat/mode`; `--full` switches back. `.zshrc` now only enables Oh My Zsh plugins for tools that are installed, and falls back to apt's fzf shell integration
- `downbeat` command (`home/.local/bin/downbeat`): `update` (fast-forward pull, then `install.sh`), `status` (new release tag on GitHub, uncommitted changes under `home/`, and `brew bundle check`), and `edit` (open the clone in my editor, or print its path)
- Ghostty: `cmd+shift+e` also toggles split zoom (alongside `cmd+shift+enter`)

## [3.1.1] - 2026-10-07

### Added
- MIT `LICENSE`, mentioned at the end of the README
- `.github/dependabot.yml`: weekly `github-actions` updates

### Changed
- Ghostty uses Courier New (`font-family`), with section headers in the config
- GitHub Actions are pinned to full commit SHAs (version in a comment) so a moved tag can't run someone else's code

## [3.1.0] - 2026-10-05

### Added
- `awswami [profile]` is now a function: the caller identity for the default or given AWS profile, plus `AccountName` from `aws account get-account-information` (left empty if the role can't read it)
- Oh My Zsh completion waiting dots (`COMPLETION_WAITING_DOTS="true"`)

### Fixed
- `install.sh` no longer asks for a GitHub username on every re-run on machines without 1Password. It asks only when `user.name` is missing, or when there's no signing key and 1Password's `op-ssh-sign` is installed. Without 1Password, the message now says that instead of "No signing key"
- The GitHub username prompt rejects an email (and `DOWNBEAT_GITHUB_USER` with an `@` is ignored with a warning). Before, an email typed there became `user.name`, the key lookup failed, and signing stayed off
- CI: PRs that don't touch install files (docs, changelog) no longer wait forever on the required `install (ubuntu-latest)` / `install (macos-latest)` checks. A matrix job skipped by a job-level `if:` never expands, so those checks never reported; the skip is now per step, so both checks always run and pass in seconds when there's nothing to test

## [3.0.1] - 2026-10-05

### Fixed
- `install/node.sh` stops with a clear message when `~/.nvm/nvm.sh` exists but doesn't load (e.g. a leftover Homebrew or older nvm), and says how to replace it. Before, it carried on and ran whatever `npm` was on PATH, which failed with `nvm: command not found` and an unrelated `EEXIST` error from Homebrew's npm
- `install/node.sh` fails the step if `nvm install` or `nvm use` fails, instead of installing global tools with the wrong Node

## [3.0.0] - 2026-10-05

Breaking: `install.sh` no longer manages Claude Code config, and iTerm2 is replaced by Ghostty. On an existing install, the old `~/.claude/{agents,commands,hooks}` symlinks point at deleted files, and their hook entries stay in `~/.claude/settings.json` until you replace or remove them. Brew doesn't uninstall iTerm2; run `brew uninstall --cask iterm2` if you don't want it.

### Added
- Ghostty (cask) replaces iTerm2, with my config tracked at `home/.config/ghostty/config.ghostty` (the XDG path, read on macOS and Linux). It includes an optional, untracked `~/.config/ghostty/config.local.ghostty` for per-machine settings

### Changed
- Secret scanning and shell linting run through the [pre-commit](https://pre-commit.com) framework: `.pre-commit-config.yaml` has gitleaks (with `.gitleaks.toml`) and shellcheck. `install.sh` runs `pre-commit install` and replaces the old hand-written hook
- CI is one workflow, `ci.yml`: pre-commit plus a gitleaks-action scan of the pushed commits, and a clean-runner install test on `ubuntu-latest` and `macos-latest` (`bootstrap.sh` from the PR's commit, then a second `install.sh` run for idempotence). The Docker setup in `test/` stays for local testing
- CI runs the install test only when `install.sh`, `bootstrap.sh`, `Brewfile`, `install/`, `home/` or `ci.yml` change (pushes to `main` always run it). The pre-commit job still runs on everything

### Fixed
- Pushing no longer prompts for a username and password after an HTTPS bootstrap clone: `home/.gitconfig` rewrites GitHub pushes to SSH (`pushInsteadOf`), so clones stay HTTPS and pushes use your SSH key. `gh auth login` is no longer needed to push

### Removed
- Claude Code config: `home/.claude/` (agents, `/new-spec`, hooks), `claude/` and the `~/.claude/settings.json` merge step in `install.sh`. I keep it in a separate harness setup now. Existing installs keep dangling symlinks in `~/.claude/{agents,commands,hooks}` and the old hook entries in `~/.claude/settings.json` until something else replaces them
- `scripts/setup-hooks.sh`
- `.github/workflows/secret-scan.yml` (replaced by `ci.yml`)

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

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VoteNetti's personal workstation setup, published as a public repo. The defaults are personal preferences, and the README is written in first person to say so; keep that voice when editing docs. A lightweight, cross-platform (macOS + Linux) workstation setup: **Homebrew is the only package manager** and **configuration lives in symlinked dotfiles**. `install.sh` is a single, idempotent entry point; re-running it is also how you update. On a new machine, `bootstrap.sh` (run via `curl | bash` from the public repo) gets git, clones to `~/.downbeat` (`DOWNBEAT_DIR`), and runs `install.sh`.

## Architecture

- `Brewfile` — all packages. Formulae outside `if OS.mac?` must also work with Homebrew on Linux; casks and macOS-only formulae (e.g. `powershell`) go inside the block.
- `home/` — mirrors `$HOME`. `link_dotfiles()` in `install.sh` symlinks each *file* (never a directory) to the same path under `$HOME`, backing up any real file to `*.bak.<timestamp>`. File-level linking keeps tool-owned directories like `~/.claude` and `~/.oh-my-zsh` real.
- Machine-specific settings go in untracked `~/.zshrc.local`, `~/.zprofile.local`, `~/.gitconfig.local`. Never write per-machine values into `home/`.
- No identity is tracked. `home/.gitconfig` holds preferences only (SSH signing on for commits and tags). `configure_git_identity()` writes name, email and the public signing key to `~/.gitconfig.local`: from `DOWNBEAT_GITHUB_USER` / `DOWNBEAT_GIT_EMAIL`, then saved values, then a prompt. The key comes from GitHub's public `users/<user>/ssh_signing_keys` endpoint (no login), and `~/.config/git/allowed_signers` is generated from it. Signing uses 1Password's `op-ssh-sign` and is turned off in `~/.gitconfig.local` when there's no signer or key. Commits are signed via 1Password, so committing may prompt the user for Touch ID.
- `claude/settings.base.json` + `claude/merge-settings.jq` — merged into `~/.claude/settings.json` with `jq` (not symlinked, because Claude Code writes to that file).
- `install/node.sh` — nvm via the official installer (`PROFILE=/dev/null`, so it never edits rc files), Node LTS, global npm tools. Oh My Zsh's `nvm` plugin lazy-loads nvm.
- Linux only needs apt for Homebrew's prerequisites and zsh; everything else comes from brew.
- Docker comes from the `docker-desktop` cask only; never add brew's `docker`/`docker-completion` formulae (they conflict with Desktop's bundled CLI). VS Code settings are not managed (Settings Sync).

- The clone location is permanent: dotfiles symlink into it. `install.sh` uses its own directory (`REPO_DIR`), so it works from any clone.
- `install.sh` runs `pre-commit install` for this repo (gitleaks + shellcheck, configured in `.pre-commit-config.yaml`) and ends with a `gh auth login` reminder if GitHub CLI isn't logged in.

## Development Commands

- Syntax check: `bash -n install.sh install/node.sh` and `zsh -n home/.zshrc home/.zprofile`
- List Brewfile entries: `brew bundle list --file=Brewfile --all`
- Test the settings merge without writing: `jq -s -f claude/merge-settings.jq ~/.claude/settings.json claude/settings.base.json`
- Lint and scan everything: `pre-commit run --all-files`
- Run installation: `./install.sh`

## Testing Approach

- Syntax validation with `bash -n`
- CI (`.github/workflows/ci.yml`) is the main test: `pre-commit run --all-files`, then `bootstrap.sh` (with `DOWNBEAT_REPO` set to the checkout) plus a second `install.sh` run on `ubuntu-latest` and `macos-latest`, using `DOWNBEAT_GITHUB_USER` / `DOWNBEAT_GIT_EMAIL` and expecting signing off
- Docker (below) stays for local experiments on clean Ubuntu
- Idempotent script design (safe to run multiple times)

### Docker Testing

Test installation scripts in a clean Ubuntu environment using Docker:

**Quick Start:**
```bash
cd test && ./test-in-docker.sh
```

**Manual Docker Commands:**
```bash
# Build and start container (run from test/)
docker compose up -d

# Enter the container
docker compose exec ubuntu-test bash

# Inside container - test your scripts
bash -n install.sh  # Syntax check
./install.sh        # Run installation

# Test the new-machine flow from the mounted repo's committed HEAD
DOWNBEAT_REPO=~/downbeat bash ~/downbeat/bootstrap.sh

# Stop container
docker compose down

# Rebuild from scratch (clean state)
docker compose down && docker compose build --no-cache
```

The Docker setup provides:
- Clean Ubuntu 22.04 environment
- Non-root user with sudo access
- Live volume mounting (changes to scripts reflect immediately)
- Isolated testing without affecting host system

## Release Process

This project uses semantic versioning with git tags:
- MAJOR: breaking changes (restructured scripts, removed tools)
- MINOR: new features (new tool, new config, new OS support)
- PATCH: fixes (bug fixes, doc updates, config tweaks)

Steps (`main` is protected, so the changelog goes in through a PR):
1. In the PR that completes the release (or a dedicated `Prepare release vX.Y.Z` PR), change `## [Unreleased]` in `CHANGELOG.md` to `## [X.Y.Z] - date`
2. Merge the PR, then `git switch main && git pull`
3. Tag `main` with a signed annotated tag: `git tag -a vX.Y.Z -m "vX.Y.Z: Brief description"` (the branch-protection hook allows tagging)
4. Push: `git push origin vX.Y.Z`

Versions are milestones: `bootstrap.sh` always installs from `main`, not from a tag.

A GitHub Action (`.github/workflows/release.yml`) automatically creates a GitHub Release when a version tag is pushed.

## Claude Code Configuration

Claude Code config is deployed to user scope (`~/.claude/`) by `install.sh`.

| Source | Destination | How |
|--------|-------------|-----|
| `home/.claude/agents/*.md` | `~/.claude/agents/` | Symlinked per file (7 Software Factory agents) |
| `home/.claude/commands/*.md` | `~/.claude/commands/` | Symlinked per file (`/new-spec`) |
| `home/.claude/hooks/*.sh` | `~/.claude/hooks/` | Symlinked per file (executable bit tracked in git) |
| `claude/settings.base.json` | `~/.claude/settings.json` | Merged by `merge_claude_settings()` |

**Agents** (Software Factory pattern):
- `builder` — implements features from specs (opus, green)
- `validator` — runs scenarios and reports pass/fail (sonnet, blue)
- `security-auditor` — static analysis and CVE scanning; triggers proactively on auth/dep changes (opus, red)
- `planner` — decomposes large tasks into ordered seeds (opus, yellow)
- `explorer` — read-only codebase navigation (haiku, cyan)
- `deployer` — GitHub Actions + AWS deployments, runs in background (sonnet, orange)
- `specifier` — turns rough ideas into build-ready specs; reads spec files only (opus, purple)

**Hooks wired into `~/.claude/settings.json` under `PreToolUse`:**
- `commit-msg-check.sh` — enforces `[feat|fix|chore|infra|docs]` prefix (no `[spec-NNN]` — that's project-level)
- `branch-protection.sh` — blocks direct commits to main
- `pull-before-push.sh` — requires pull if local branch is behind remote

**Settings merge strategy:** `claude/merge-settings.jq` leaves every key it doesn't own alone (e.g. `model`, `effortLevel`). It appends missing `permissions.allow` entries in order, removes the base hook commands from wherever they are, then re-appends the base hook entries. That keeps the user's own hooks and means re-running never duplicates them.

## Secret Scanning

- Pre-commit hook via gitleaks, managed by the pre-commit framework (`.pre-commit-config.yaml`); `install.sh` installs it, or run `pre-commit install` on its own. shellcheck runs from the same config
- Never run `pre-commit install` in a checkout without that config: every commit fails
- CI (`.github/workflows/ci.yml`) runs `pre-commit run --all-files` and a full-history `gitleaks detect` (the pre-commit gitleaks hook only scans staged changes)
- Configuration in `.gitleaks.toml`
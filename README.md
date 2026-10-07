# downbeat

This is a baseline for setting up new machines and remembering how I got there. One command takes a fresh Mac or Linux box to my working environment: Homebrew for every package, dotfiles symlinked from this repo, and signed commits.

The name is a nod to the recording sessions I used to work. The start of the day was the "downbeat": the moment the musicians, producers, engineers and artists expected the studio to be ready to press record. A lot of work came before it: setting up the room, instrument drop-off, testing every signal path. This repo makes that work repeatable.

Everything here reflects my preferences: the tools I use, the defaults I like. It's public so I can call it without a login. If you want to use it, see [Using it yourself](#using-it-yourself).

## My choices

- **Homebrew everywhere.** One package manager on macOS and Linux, one [`Brewfile`](Brewfile). Simple, and configured in one file.
- **Symlinks, not copies.** Dotfiles live in this repo and are linked into place, so a change on any machine shows up in `git status` instead of quietly drifting.
- **zsh with Oh My Zsh.** A great zsh customization [ecosystem](https://github.com/ohmyzsh/).
- **nvm for Node.js,** loaded lazily so the shell starts fast.
- **1Password for secrets.** Commits and tags are signed with an SSH key that only exists in 1Password.
- **Docker Desktop** provides Docker on macOS with a GUI.
- **Re-running is updating.** `install.sh` is safe to run any time; `downbeat update` is the shortcut.

## Prerequisites

**macOS**
- An administrator account (the Homebrew installer needs `sudo`)
- An internet connection. `curl` is already installed; `bootstrap.sh` gets everything else, including git.

**Linux**
- Ubuntu or Debian (anything with `apt-get`), x86_64 or arm64
- A regular user with `sudo` access. Homebrew refuses to run as root.
- `curl` (`sudo apt-get install -y curl` if it's missing)

**Optional, for signed commits**
- The 1Password app, with its SSH agent turned on
- An SSH key in 1Password, listed in `~/.config/1Password/ssh/agent.toml` and registered on GitHub as a **signing** key

`install.sh` finds the public key itself by asking GitHub, so there's nothing to copy. Without 1Password or a registered key, setup still works: `install.sh` turns signing off on that machine.

**Optional, to push changes**
- A GitHub account. `gh` comes from the Brewfile; log in after setup (see below).

## New machine

```bash
curl -fsSL https://raw.githubusercontent.com/VoteNetti/downbeat/main/bootstrap.sh | bash
```

`bootstrap.sh` gets git (on macOS by installing Homebrew, which brings the Xcode Command Line Tools), clones this repo to `~/.downbeat`, and runs `./install.sh`. No GitHub login needed.

The first run asks two questions, then remembers the answers on that machine:

```
GitHub username: VoteNetti
Git email (one verified on your GitHub account): me@johnnetti.com
✓ Signing key "GitHub - VoteNetti - Signing" found on GitHub
```

To skip the questions, set the answers up front:

```bash
DOWNBEAT_GITHUB_USER=VoteNetti DOWNBEAT_GIT_EMAIL=me@johnnetti.com \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/VoteNetti/downbeat/main/bootstrap.sh)"
```

Dotfiles are symlinked into `~/.downbeat`, so the clone stays there. To use a different location, set `DOWNBEAT_DIR` before running the one-liner and leave it there too.

The clone uses HTTPS so it works before any keys exist. `home/.gitconfig` rewrites GitHub pushes to SSH, so pushing needs your SSH key on GitHub and nothing else. `gh auth login` is only for `gh` itself (pull requests, issues).

## The `downbeat` command

`home/.local/bin/downbeat` is linked into `~/.local/bin`, so it's on my PATH after the first install.

| Command | What it does |
|---|---|
| `downbeat update` | Fast-forward pulls the clone, then runs `./install.sh` |
| `downbeat status` | Checks GitHub (over plain HTTPS, no key needed) for a new release tag, shows uncommitted changes under `home/` (say, a tool appended to `~/.zshrc`), and runs `brew bundle check` |
| `downbeat edit` | Opens the clone in `$VISUAL`/`$EDITOR` (or VS Code); with neither, or inside `$(...)`, prints the path, so `cd "$(downbeat edit)"` works |

`./install.sh` installs anything new in the `Brewfile`, upgrades what's outdated, and re-links dotfiles. If the pull can't fast-forward, `downbeat update` stops before installing.

## What install.sh does

1. **Linux only:** installs Homebrew's prerequisites and zsh via apt (`build-essential procps curl file git zsh`)
2. Installs [Homebrew](https://brew.sh) (on macOS this also installs the Xcode Command Line Tools)
3. Trusts the third-party tap formulae in the Brewfile, then runs `brew bundle`
4. Installs [Oh My Zsh](https://ohmyz.sh)
5. Symlinks every file in `home/` to the same path under `$HOME`
6. Sets up git identity and signing: asks for a GitHub username and email (first run only), looks up the public signing key on GitHub, and signs through 1Password (or turns signing off)
7. Installs the [pre-commit](https://pre-commit.com) hooks in this repo (gitleaks and shellcheck)
8. Installs nvm, Node.js LTS and global npm tools (`install/node.sh`)
9. Sets zsh as the default shell
10. Reminds me to run `gh auth login` if GitHub CLI isn't logged in

## Layout

```
downbeat/
  bootstrap.sh          # New-machine one-liner: get git, clone, run install.sh
  install.sh            # Entry point (safe to re-run)
  .pre-commit-config.yaml  # gitleaks + shellcheck hooks
  Brewfile              # All packages; macOS-only casks wrapped in `if OS.mac?`
  home/                 # Mirrors $HOME; each file is symlinked into place
    .zshrc
    .zprofile
    .gitconfig
    .local/bin/downbeat # The downbeat command (update, status, edit)
    .oh-my-zsh/custom/plugins/netti-git/
  install/node.sh       # nvm + Node LTS + global npm tools
  test/                 # Docker-based Ubuntu testing
```

## Dotfiles

Editing `~/.zshrc` edits `home/.zshrc` in this repo. That also catches tools that append to rc files: their changes show up in `git status`.

Files are linked one at a time, never whole directories, so tool-owned directories like `~/.oh-my-zsh` stay real and writable. An existing file is moved to `<file>.bak.<timestamp>` before it's replaced.

To add a dotfile, put it in `home/` at its path relative to `$HOME` and re-run `./install.sh`.

### Machine-specific settings

These are sourced or included if present, and never tracked:

| File | Use for |
|---|---|
| `~/.zshrc.local` | Per-machine aliases and tool integrations |
| `~/.zprofile.local` | Per-machine PATH changes (e.g. Docker Desktop) |
| `~/.gitconfig.local` | Written by `install.sh`: name, email, signing key, and the 1Password signer (or signing turned off) |
| `~/.config/ghostty/config.local.ghostty` | Per-machine Ghostty settings (font size, etc.) |

Use `git config --file ~/.gitconfig.local ...` rather than `git config --global ...`, which would write to the tracked `home/.gitconfig`.

### Ghostty

My Ghostty config is `home/.config/ghostty/config.ghostty`, at the XDG path Ghostty reads on both macOS and Linux. On macOS, Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` *after* the XDG file, so anything there overrides this repo. Keep that file absent. Reload with `cmd+shift+,`.

### Git identity and signing

No identity lives in this repo. `home/.gitconfig` only holds my preferences, including signing every commit and tag with SSH. Who is signing is set per machine in `~/.gitconfig.local`:

- **Name and email:** from `DOWNBEAT_GITHUB_USER` and `DOWNBEAT_GIT_EMAIL`, or a prompt on the first run. The name defaults to the GitHub username. The email should be one verified on that GitHub account, or commits won't show as Verified.
- **Signing key:** the public SSH signing key registered on that GitHub account, read from `https://api.github.com/users/<username>/ssh_signing_keys` (public, no login). With more than one, `install.sh` asks which.
- **Signer:** 1Password's `op-ssh-sign`, so the private key never leaves 1Password. On machines without 1Password (servers, the Docker test), or with no signing key, signing is turned off there instead.

`install.sh` also writes `~/.config/git/allowed_signers` from the email and key, so `git log --show-signature` can verify commits locally.

Re-runs reuse what's saved and never ask again. The GitHub username is only needed for the name or, on a machine with 1Password, the signing key, so a machine without 1Password stops asking once the name is saved. A username containing `@` is rejected, since the key lookup needs the username, not the email. To change identity or pick up a rotated key, edit or clear the values in `~/.gitconfig.local` and re-run `./install.sh`.

## Packages

Edit the [`Brewfile`](Brewfile) and re-run `./install.sh` (or just `brew bundle`). To list installed packages that aren't in the Brewfile:

```bash
brew bundle cleanup
```

Not in the Brewfile:
- **Docker CLI:** comes with the `docker-desktop` cask. Brew's `docker` formula conflicts with it.
- **Node.js:** `install/node.sh` uses the official nvm installer. Global npm tools go in `NPM_GLOBALS` in that script.
- **VS Code settings:** VS Code Settings Sync.

## Secret scanning

`install.sh` installs [pre-commit](https://pre-commit.com) hooks in this repo, so every commit is scanned with [gitleaks](https://github.com/gitleaks/gitleaks) (and my shell scripts are linted with [shellcheck](https://www.shellcheck.net)) before it's created. That matters here because dotfiles are symlinked into the repo: anything a tool appends to `~/.zshrc` lands in a tracked file. CI runs the same hooks, plus a gitleaks-action scan, on every push and pull request.

## Testing

```bash
bash -n install.sh      # Syntax check
pre-commit run --all-files  # gitleaks + shellcheck
cd test/ && ./test-in-docker.sh   # optional: poke around in a clean Ubuntu container
```

GitHub Actions (`.github/workflows/ci.yml`) is the real test. On every pull request and push to `main` it runs `pre-commit run --all-files`. When a file that affects the install changes (or on any push to `main`), it also runs `bootstrap.sh` from that commit on clean `ubuntu-latest` and `macos-latest` runners, runs `install.sh` a second time to check it's idempotent, and checks the result. There's no 1Password on a runner, so signing is expected to be off there. The Docker setup in `test/` stays for trying things locally.

See [CLAUDE.md](CLAUDE.md) for the full testing instructions.

## Using it yourself

The one-liner sets up *your* git identity and signing key, since it asks for them. Everything else (packages, shell setup) is mine, so to make it yours, fork it and change:

1. **`Brewfile`:** your own tools
2. **`bootstrap.sh`:** point `DOWNBEAT_REPO` at your fork
3. **`home/`:** anything else you'd do differently

## Versioning

[Semantic versioning](https://semver.org/) with git tags. Versions are milestones: `bootstrap.sh` always installs from `main`, not from a tag. See [CHANGELOG.md](CHANGELOG.md) for release notes and [CLAUDE.md](CLAUDE.md) for the release process.

## License

[MIT](LICENSE). Take whatever is useful; keep the copyright notice.

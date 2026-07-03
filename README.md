# Dotfiles

macOS development environment managed as code.

## Setup

```bash
make setup
```

This runs modular setup scripts in order:

1. **Homebrew** — installs Homebrew if missing, then installs packages from `Brewfile` and Node.js LTS via nvm
2. **Claude Code** — symlinks config, agents, skills, and hooks into `~/.claude/`
3. **Git Identity** — resolves SSH signing keys from 1Password, generates the `mode` function for work/home switching, and sets work as default
4. **Symlinks** — links dotfiles (bash, zsh, git, editor, macOS), shell functions, global git hooks (`~/.git_hooks`), and the SSH client config into `~/`
5. **VS Code** — symlinks `settings.json` and `keybindings.json`, and installs tracked extensions
6. **macOS** — sets zsh as default shell, imports the `macdump` defaults snapshot (if present), and applies macOS preferences
7. **Hosts** — syncs `/etc/hosts` (sudo) with the canonical copy in `macos/hosts`

## Doctor

```bash
make doctor
```

Read-only health check that verifies the machine still matches the repo: symlinks resolve, 1Password is signed in (both accounts) with the SSH agent running, git signing is configured, the Brewfile is satisfied, Node is on LTS, `/etc/hosts` is in sync, the login shell is zsh, and the global git hooks are wired. Changes nothing; exits non-zero if anything needs attention.

## macOS

```bash
make macos
```

Reapplies just the macOS configuration without a full setup: the default shell and preferences (`macos.sh` — `.osx` plus the `macdump`/`menudump` snapshots), and the `/etc/hosts` sync (`hosts.sh`). Useful after editing anything in `macos/` or running `macdump`/`menudump`.

> **First run on a fresh machine:** the Git Identity step reads your SSH signing keys from 1Password via the `op` CLI. If 1Password isn't signed in yet (`op signin`) with CLI integration enabled, that step is skipped with a warning and listed under "Needs attention" at the end — sign in and re-run `make setup` to finish git signing setup.

## Work/Home Mode

Switch git identity and view Claude Code account:

```bash
mode work      # git identity -> your work email (from config.sh)
mode home      # git identity -> your personal email (from config.sh)
mode status    # show current git identity + Claude Code account
```

Claude Code account switching is manual — use `/logout` in the VSCode extension.

A global pre-commit hook (`git/hooks/pre-commit`, wired via `core.hooksPath`) blocks commits to repos under the work GitHub orgs (`WORK_GITHUB_ORGS` in `config.sh`) when the git email isn't the work one - so forgetting `mode work` fails loudly instead of landing personal-identity commits in work repos. The hook chains to each repo's own `pre-commit` afterwards; repos that set `core.hooksPath` locally (e.g. husky) bypass it.

## Configuration

User-specific values live in `config.sh` (gitignored). Copy the template and edit it:

```bash
cp config.sh.example config.sh
```

- Git name and emails
- 1Password account references and signing key paths
- Brewfile reminder interval

If you register a plugin (below) that ships its own `config.sh`, `make plugin` links it here for you, so you don't need to create the file by hand.

## Plugins

A **plugin** is a separate repo (typically private) that layers extra config on top of this one - for example work-specific Claude Code skills, a Jira doc, internal `/etc/hosts` entries, and machine identity. This keeps the public repo free of anything private while still managing everything from one setup flow.

A plugin mirrors this repo's layout. Any of these parts is picked up if present:

| In the plugin | Merged into |
|---|---|
| `claude/agents/*.md`, `claude/skills/*/`, `claude/hooks/*`, `claude/docs/*` | `~/.claude/` alongside this repo's own |
| `claude/settings.json` | Replaces this repo's settings (one plugin should own it) |
| `config.sh` | Linked to the repo root as `config.sh` |
| `macos/hosts` | Appended to the composed `/etc/hosts` |

Register and apply one with:

```bash
make plugin DIR=/path/to/plugin-repo
```

This symlinks it under `plugins/<name>` (gitignored), then re-runs the Claude Code and hosts steps so it takes effect immediately. To unregister, delete the symlink under `plugins/` and run `make claude`.

## Brewfile

```bash
brewdump       # regenerate Brewfile from installed packages (also runs codedump)
brewsnooze     # dismiss the "Brewfile is stale" reminder for 30 days
```

A terminal reminder appears if the Brewfile hasn't been synced in 30 days (configurable via `BREWDUMP_REMINDER_DAYS` in `config.sh`). A similar monthly reminder appears if the local dotfiles repo has fallen behind origin.

## Dock

```bash
dockdump       # sync the current Dock app order into macos/.osx
```

Arrange your Dock how you like, then run `dockdump` to capture it. The app list is stored between the `dock-apps` markers in `macos/.osx` and reapplied with `dockutil` on the next `make setup`.

## macOS Defaults

```bash
macdump        # snapshot NSGlobalDomain defaults to macos/GlobalDefaults.plist
```

The snapshot (if present) is imported by the macOS setup step, so global preferences round-trip onto a fresh machine.

## Menu Bar

```bash
menudump       # snapshot the menu bar / Control Center layout into macos/
```

Arrange the menu bar how you want in System Settings → Control Center (which items show, and whether each shows always or only when active), then run `menudump`. It captures the `com.apple.controlcenter` (per-host and main) and `com.apple.TextInputMenu` domains as plists, which the macOS setup step re-imports and restarts Control Center to apply. Because the visibility values are version-specific integer codes, snapshotting the real state is more reliable than hand-writing them. Note: Spotlight's menu bar icon is not exposed via defaults on current macOS, so it can't be captured this way.

## VS Code

Config lives in `vscode/` and is version-controlled:

- `settings.json` and `keybindings.json` are **symlinked** into VS Code's User directory, so edits in VS Code write straight back to the repo — no sync step needed.
- `extensions.txt` is a snapshot of installed extensions, reinstalled on `make setup`. Refresh it after adding/removing extensions:

```bash
codedump        # snapshot installed VS Code extensions into vscode/extensions.txt
```

> VS Code's built-in **Settings Sync must be turned off** (Command Palette → "Settings Sync: Turn Off") — otherwise it fights the symlinks for ownership of the config files.

## Structure

```
config.sh.example      # User-specific configuration template (copy to config.sh)
plugins/               # Registered plugin symlinks (gitignored)
Brewfile               # Homebrew packages
Makefile               # make setup entry point
templates/             # Templates with 1Password placeholders
  mode.sh.template     # Work/home mode switching function
setup.sh               # Bootstrap entry point
setup/
  brew.sh              # Homebrew + Brewfile + nvm
  claude.sh            # Claude Code config symlinks (repo + plugins)
  git.sh               # Git identity + hooks
  symlinks.sh          # Dotfile symlinks
  macos.sh             # Shell + macOS preferences
  hosts.sh             # /etc/hosts sync (repo + plugin fragments)
  plugin.sh            # Register a plugin (make plugin)
  doctor.sh            # Read-only health check (make doctor)
zsh/
  .zshrc               # Shell startup
  .zsh_prompt          # Prompt with git email
  .zsh_aliases         # Aliases
  functions/           # Shell functions (symlinked to ~/.zsh_functions/)
git/
  .gitconfig           # Shared git config
  .gitconfig.local.example
  .gitignore_global    # Global git excludes (symlinked to ~/.gitignore_global)
  hooks/               # Global git hooks (symlinked to ~/.git_hooks)
ssh/
  config               # SSH client config (symlinked to ~/.ssh/config; never keys)
claude/                # Claude Code config (symlinked to ~/.claude/)
```

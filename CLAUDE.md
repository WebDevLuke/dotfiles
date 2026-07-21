# Dotfiles

## Keeping `make help` in sync

`make help` auto-generates its listing by parsing comments from three sources: the `Makefile`, `zsh/.zsh_aliases`, and `zsh/functions/*.sh`. The description a command shows in `make help` **is** the comment you write next to it, so every new command must be added with the right comment, under the right category, or it will be missing or uncategorised in the help output.

Whenever you add, rename, or remove a command, update its source so `make help` stays correct, then run `make help` to confirm it appears in the expected section.

When renaming or removing a command, grep the whole repo for the old name - `README.md`, `setup/*.sh`, `zsh/.zshrc`, and this file - not just its source, and update every reference. Stale references in docs and startup reminders are a recurring miss.

### Adding a make target

- Put an inline `## <description>` on the target line - this text is what `make help` prints.
- Place the target under the correct `##@ <Category>` header (currently `Setup` and `Snapshots`). Add a new `##@ <Category>` header if it belongs in a new group.
- Add the target name to `.PHONY`.

### Adding an alias (`zsh/.zsh_aliases`)

- Put a `# <description>` comment on the line directly above the `alias`.
- Place it under the correct `## <Category>` header (currently Navigation, Git, Config, Network, Utilities, Dotfiles). Add a new `## <Category>` header for a new group.

### Adding a function (`zsh/functions/*.sh`)

- Put a `# <description>` comment directly above the `function name() {` line.
- Functions with a make wrapper (`dockdump`, `menudump`) and `mode` (hardcoded in the Identity block) are intentionally excluded from the Functions section to avoid duplication. If you add another function with a make wrapper, add its name to the exclusion regex in the `help` recipe's Functions `awk`.

### Identity section

`mode` and `switch` are listed in a hardcoded Identity block inside the `help` recipe (not auto-parsed, because `switch` is an alias and `mode` a function that both wrap the same identity concept). Update that block directly if their usage changes.

### Plugins

Registered plugins live under `plugins/<name>/` (symlinks, gitignored) and mirror the repo layout. `make help` merges plugin-contributed commands automatically - no manual editing of the main repo is needed. For a plugin's commands to show up, put them in the plugin using the same conventions as above:

- **Make targets** go in a `plugins/<name>/*.mk` fragment (not a full `Makefile`, which would clash). The main Makefile pulls them in via `-include`, so they both run and appear in `make help`.
- **Aliases** go in `plugins/<name>/zsh/.zsh_aliases`, **functions** in `plugins/<name>/zsh/functions/*.sh` - both picked up by the `ALIAS_FILES` / `FUNC_FILES` globs.

Note: `make help` *lists* plugin aliases/functions, but plugin `zsh/` files are not yet symlinked/sourced by `plugin.sh`, so they won't actually load into the shell until that's wired up. Plugin `*.mk` targets do run.

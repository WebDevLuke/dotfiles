#!/usr/bin/env bash
# Read-only health check: verifies the machine still matches the repo.
# Run via `make doctor`. Changes nothing; exits 1 if anything needs attention.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$REPO/config.sh" ] && source "$REPO/config.sh"

WARNINGS=0

# Compose the canonical hosts file: repo base + every registered plugin fragment.
compose_hosts() {
	cat "$REPO/macos/hosts"
	for plugin in "$REPO/plugins"/*; do
		[ -f "$plugin/macos/hosts" ] && cat "$plugin/macos/hosts"
	done
}

ok() {
	echo "  ✅ $1"
}

warn() {
	echo "  ⚠️  $1"
	WARNINGS=$((WARNINGS + 1))
}

echo ""
echo "══════════════════════════════════════"
echo "  🩺 Doctor"
echo "══════════════════════════════════════"
echo ""

# Symlinks that setup should have created, each resolving into the repo
links=(
	~/.zshrc ~/.zsh_prompt ~/.zsh_aliases
	~/.gitconfig ~/.gitignore_global ~/.editorconfig ~/.osx
	~/.git_hooks ~/.ssh/config
	~/.claude/CLAUDE.md ~/.claude/settings.json
)
broken_links=()
for link in "${links[@]}"; do
	if [ ! -L "$link" ] || [ ! -e "$link" ]; then
		broken_links+=("$link")
	fi
done
if [ "${#broken_links[@]}" -eq 0 ]; then
	ok "All dotfile symlinks resolve"
else
	warn "Missing/broken symlinks: ${broken_links[*]} - run 'make setup'"
fi

# Dead symlinks left behind in the fan-out directories
dead=0
for link in ~/.claude/agents/* ~/.claude/skills/* ~/.claude/hooks/* ~/.zsh_functions/*; do
	[ -L "$link" ] && [ ! -e "$link" ] && dead=$((dead + 1))
done
if [ "$dead" -eq 0 ]; then
	ok "No dead symlinks in ~/.claude or ~/.zsh_functions"
else
	warn "$dead dead symlink(s) in ~/.claude or ~/.zsh_functions - run 'make setup'"
fi

# Generated identity artefacts
if [ -f "$REPO/zsh/functions/mode.sh" ]; then
	ok "mode function generated"
else
	warn "mode function missing - run 'make setup' (with 1Password signed in)"
fi
if grep -q signingkey ~/.gitconfig.local 2>/dev/null; then
	ok "Git signing identity configured"
else
	warn "~/.gitconfig.local missing or has no signingkey - run 'make setup' (with 1Password signed in)"
fi

# 1Password CLI sessions and SSH agent
for account in "$WORK_1PW_ACCOUNT" "$PERSONAL_1PW_ACCOUNT"; do
	[ -z "$account" ] && continue
	if /opt/homebrew/bin/op whoami --account "$account" &>/dev/null; then
		ok "1Password signed in: $account"
	else
		warn "1Password not signed in: $account - run 'op signin --account $account'"
	fi
done
if [ -S ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ]; then
	ok "1Password SSH agent running"
else
	warn "1Password SSH agent not running - enable it in 1Password Settings > Developer"
fi

# Homebrew bundle
if /opt/homebrew/bin/brew bundle check --file="$REPO/Brewfile" &>/dev/null; then
	ok "Brewfile satisfied"
else
	warn "Brewfile packages missing - run 'make setup' or 'brew bundle install'"
fi

# Node vs cached LTS (cache written by .zshrc, refreshed monthly)
node_current=$(node --version 2>/dev/null)
node_lts=$(cat ~/.node_lts_cache 2>/dev/null)
if [ -z "$node_lts" ] || [ "$node_current" = "$node_lts" ]; then
	ok "Node.js on LTS (${node_current:-not installed})"
else
	warn "Node.js $node_current is not LTS ($node_lts) - run 'nvm install --lts && nvm alias default lts/*'"
fi

# Hosts file sync (repo base + plugin fragments)
if compose_hosts | cmp -s - /etc/hosts; then
	ok "/etc/hosts in sync with repo"
else
	warn "/etc/hosts differs from composed hosts - run 'make setup'"
fi

# Registered plugins (entries under plugins/, including broken symlinks)
shopt -s nullglob
plugins=("$REPO/plugins"/*)
shopt -u nullglob
if [ "${#plugins[@]}" -eq 0 ]; then
	ok "No plugins registered"
else
	for plugin in "${plugins[@]}"; do
		name="$(basename "$plugin")"
		if [ -d "$plugin" ]; then
			ok "Plugin '$name' -> $(cd "$plugin" && pwd -P)"
		else
			warn "Plugin '$name' is broken - re-run 'make plugin' or remove plugins/$name"
		fi
	done
fi

# Login shell
login_shell="$(dscl . -read "/Users/$(whoami)" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$login_shell" = "/bin/zsh" ]; then
	ok "Login shell is zsh"
else
	warn "Login shell is ${login_shell:-unknown}, expected /bin/zsh - run 'make setup'"
fi

# Global git hooks
if [ "$(git config --global core.hooksPath)" = "~/.git_hooks" ] && [ -x ~/.git_hooks/pre-commit ]; then
	ok "Global git hooks wired (identity guard active)"
else
	warn "Global git hooks not wired - run 'make setup'"
fi

echo ""
if [ "$WARNINGS" -eq 0 ]; then
	echo "  All checks passed."
else
	echo "  $WARNINGS check(s) need attention."
fi
echo ""

exit $((WARNINGS > 0 ? 1 : 0))

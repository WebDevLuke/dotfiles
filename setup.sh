#!/usr/bin/env bash
################################################################################
# SETUP
#
# Bootstraps a fresh macOS machine by sourcing modular setup scripts from the
# setup/ directory. Each script handles one concern:
#
#   brew.sh      — Homebrew and Brewfile packages
#   claude.sh    — Claude Code config into ~/.claude/
#   git.sh       — Machine-specific git identity and signing keys
#   symlinks.sh  — Dotfiles and shell functions into ~/
#   vscode.sh    — VS Code config symlinks and tracked extensions
#   macos.sh     — Default shell and macOS preferences
#   hosts.sh     — Syncs /etc/hosts with the repo copy
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# config.sh holds machine/identity details (git identity, 1Password refs) and is
# gitignored, so it never exists on a fresh clone. Require it up front rather than
# letting later steps skip silently.
if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
	echo ""
	echo "══════════════════════════════════════"
	echo "  ⛔ Missing config.sh"
	echo "══════════════════════════════════════"
	echo ""
	echo "  setup needs a config.sh before it can run. Create one with either:"
	echo ""
	echo "    cp config.sh.example config.sh   # then edit the values"
	echo "    make plugin DIR=<path>           # if a plugin provides one"
	echo ""
	exit 1
fi

# Collected by the sourced setup scripts and reported at the end.
SETUP_WARNINGS=()

source "$SCRIPT_DIR/setup/brew.sh"
source "$SCRIPT_DIR/setup/claude.sh"
source "$SCRIPT_DIR/setup/git.sh"
source "$SCRIPT_DIR/setup/symlinks.sh"
source "$SCRIPT_DIR/setup/vscode.sh"
source "$SCRIPT_DIR/setup/macos.sh"
source "$SCRIPT_DIR/setup/hosts.sh"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  ✅ All done!"
echo "══════════════════════════════════════"
echo ""
echo "  Switch identity:  mode work | mode home"
echo "  Check identity:   mode status"
echo ""

if [ "${#SETUP_WARNINGS[@]}" -gt 0 ]; then
	echo "══════════════════════════════════════"
	echo "  ⚠️  Needs attention"
	echo "══════════════════════════════════════"
	echo ""
	for _w in "${SETUP_WARNINGS[@]}"; do
		echo "  - $_w"
	done
	echo ""
fi

exec zsh

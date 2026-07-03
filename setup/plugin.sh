#!/usr/bin/env bash
# Registers a private plugin with the dotfiles repo.
#
# A plugin is a directory that mirrors this repo's layout (any of
# claude/agents, claude/skills, claude/hooks, claude/docs, claude/settings.json,
# config.sh, macos/hosts). Registering it symlinks it under plugins/<name> and
# applies it, so its content merges on top of the repo's own config.
#
# Usage: make plugin DIR=/path/to/plugin-repo

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${1:-}"

echo ""
echo "══════════════════════════════════════"
echo "  🔌 Register plugin"
echo "══════════════════════════════════════"
echo ""

if [ -z "$DIR" ]; then
	echo "  ✋ No plugin directory given. Usage: make plugin DIR=/path/to/plugin"
	exit 1
fi
if [ ! -d "$DIR" ]; then
	echo "  ✋ Not a directory: $DIR"
	exit 1
fi

ABS="$(cd "$DIR" && pwd -P)"
NAME="$(basename "$ABS")"

# A plugin must contribute at least one recognised part.
if [ ! -d "$ABS/claude" ] && [ ! -f "$ABS/config.sh" ] && [ ! -f "$ABS/macos/hosts" ]; then
	echo "  ✋ $ABS has none of: claude/, config.sh, macos/hosts — not a plugin."
	exit 1
fi

mkdir -p "$REPO/plugins"
ln -sfn "$ABS" "$REPO/plugins/$NAME"
echo "  ✅ Registered plugin '$NAME' -> $ABS"

# If the plugin ships a config.sh and the repo root has none, adopt it.
if [ -f "$ABS/config.sh" ] && [ ! -e "$REPO/config.sh" ]; then
	ln -sf "$ABS/config.sh" "$REPO/config.sh"
	echo "  ✅ Linked config.sh from plugin"
fi

# Apply: refresh Claude Code symlinks and re-sync /etc/hosts.
bash "$REPO/setup/claude.sh"
bash "$REPO/setup/hosts.sh"

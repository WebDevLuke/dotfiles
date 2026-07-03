#!/usr/bin/env bash
# Symlinks Claude Code configuration files into ~/.claude/.
#
# This connects the repo's Claude Code config (instructions, settings, agents,
# hooks, skills, and docs) to the global ~/.claude/ directory so Claude Code
# picks them up in every project.
#
# Plugins: any directory registered under $REPO/plugins/<name> that mirrors the
# repo layout (claude/agents, claude/skills, claude/hooks, claude/docs,
# claude/settings.json) is merged in on top of the repo's own config. A plugin's
# settings.json, if present, replaces the repo's (one plugin should own it).
#
# Files symlinked:
#   claude/CLAUDE.md           -> ~/.claude/CLAUDE.md        (global instructions)
#   claude/settings.json       -> ~/.claude/settings.json    (tool permissions)
#   claude/docs/*              -> ~/.claude/docs/<name>      (referenced sub-docs)
#   claude/agents/*.md         -> ~/.claude/agents/<name>    (agents)
#   claude/hooks/*             -> ~/.claude/hooks/<name>     (hooks)
#   claude/skills/*/           -> ~/.claude/skills/<name>    (skills)

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  🤖 Claude Code"
echo "══════════════════════════════════════"
echo ""

mkdir -p ~/.claude ~/.claude/agents ~/.claude/skills ~/.claude/hooks

# ~/.claude/docs used to be a directory symlink; make it a real dir so repo and
# plugin docs can coexist.
if [ -L ~/.claude/docs ]; then
	rm ~/.claude/docs
fi
mkdir -p ~/.claude/docs

# Remove symlinks left behind by agents/skills/hooks/docs deleted from a source
for link in ~/.claude/agents/* ~/.claude/skills/* ~/.claude/hooks/* ~/.claude/docs/*; do
	[ -L "$link" ] && [ ! -e "$link" ] && rm "$link"
done

# Symlink one source tree's claude/ config into ~/.claude/. Called for the repo
# and for each registered plugin.
link_claude_tree() {
	local base="$1"

	for f in "$base/agents"/*.md; do
		[ -f "$f" ] && ln -sf "$f" ~/.claude/agents/"$(basename "$f")"
	done

	for dir in "$base/skills"/*/; do
		[ -d "$dir" ] && ln -sfn "$dir" ~/.claude/skills/"$(basename "$dir")"
	done

	for f in "$base/hooks"/*; do
		[ -f "$f" ] || continue
		[[ "$(basename "$f")" == .* ]] && continue
		ln -sf "$f" ~/.claude/hooks/"$(basename "$f")"
	done

	for f in "$base/docs"/*; do
		[ -f "$f" ] && ln -sf "$f" ~/.claude/docs/"$(basename "$f")"
	done
}

ln -sf "$REPO/claude/CLAUDE.md" ~/.claude/CLAUDE.md

link_claude_tree "$REPO/claude"
for plugin in "$REPO/plugins"/*; do
	[ -d "$plugin/claude" ] && link_claude_tree "$plugin/claude"
done

# settings.json: a plugin's copy wins over the repo's if one exists.
settings_src="$REPO/claude/settings.json"
for plugin in "$REPO/plugins"/*; do
	if [ -f "$plugin/claude/settings.json" ]; then
		settings_src="$plugin/claude/settings.json"
	fi
done
ln -sf "$settings_src" ~/.claude/settings.json

echo "  ✅ Config symlinked"

#!/usr/bin/env bash
# Symlinks dotfiles and shell functions from the repo into the home directory.
#
# Topic directories and what they symlink to:
#   zsh/          — dotfiles (e.g. .zshrc) -> ~/
#   zsh/functions/ — function scripts      -> ~/.zsh_functions/
#   git/          — dotfiles (e.g. .gitconfig, .gitignore_global, excluding .example files) -> ~/
#   editor/       — dotfiles (e.g. .editorconfig) -> ~/
#   macos/        — dotfiles (e.g. .osx) -> ~/
#   git/hooks/    — global git hooks -> ~/.git_hooks (core.hooksPath)
#   ssh/config    — SSH client config -> ~/.ssh/config (no keys, ever)

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  🔗 Symlinks"
echo "══════════════════════════════════════"
echo ""

for topic_dir in zsh git editor macos; do
	for file in "$REPO/$topic_dir"/.*; do
		name="$(basename "$file")"
		[[ "$name" == "." || "$name" == ".." ]] && continue
		[[ "$name" == *.example ]] && continue
		[ -f "$file" ] || continue
		ln -sf "$file" ~/"$name"
	done
done

# The repo .gitignore is no longer the global excludes file (git/.gitignore_global is); drop the old symlink
[ -L ~/.gitignore ] && rm ~/.gitignore

ln -sfn "$REPO/git/hooks" ~/.git_hooks

mkdir -p ~/.ssh
ln -sf "$REPO/ssh/config" ~/.ssh/config

mkdir -p ~/.zsh_functions

# Remove symlinks left behind by functions deleted from the repo
for link in ~/.zsh_functions/*; do
	[ -L "$link" ] && [ ! -e "$link" ] && rm "$link"
done

for file in "$REPO/zsh/functions"/*; do
	[ -f "$file" ] || continue
	ln -sf "$file" ~/.zsh_functions/"$(basename "$file")"
done

# Clean up legacy bash symlinks left over from before the zsh migration
for stale in ~/.bashrc ~/.bash_profile ~/.bash_prompt ~/.bash_aliases; do
	[ -L "$stale" ] && rm -f "$stale"
done
if [ -d ~/.bash_functions ]; then
	rm -f ~/.bash_functions/*
	rmdir ~/.bash_functions 2>/dev/null
fi
[ -e ~/bash_functions ] && rm -f ~/bash_functions

echo "  ✅ Dotfiles symlinked"

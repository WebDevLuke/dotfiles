#!/usr/bin/env bash
# Symlinks VS Code user config from the repo and installs tracked extensions.
#
# Config files (settings, keybindings) are symlinked so that editing them in
# VS Code writes straight back to the repo. Extensions are reinstalled from the
# tracked vscode/extensions.txt; refresh that list with `codedump`.
#
# VS Code's built-in Settings Sync must be turned off, or it will fight these
# symlinks for ownership of the same files.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_DIR="$HOME/Library/Application Support/Code/User"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  📝 VS Code"
echo "══════════════════════════════════════"
echo ""

mkdir -p "$USER_DIR"
ln -sf "$REPO/vscode/settings.json" "$USER_DIR/settings.json"
ln -sf "$REPO/vscode/keybindings.json" "$USER_DIR/keybindings.json"
echo "  ✅ Config symlinked"

# Install any tracked extensions that aren't already present
if command -v code &>/dev/null; then
	_installed="$(code --list-extensions)"
	_count=0
	while IFS= read -r _ext; do
		[ -z "$_ext" ] && continue
		if ! grep -qix "$_ext" <<< "$_installed"; then
			code --install-extension "$_ext" &>/dev/null && _count=$((_count + 1))
		fi
	done < "$REPO/vscode/extensions.txt"
	if [ "$_count" -gt 0 ]; then
		echo "  ✅ Installed $_count missing extension(s)"
	else
		echo "  ⏭️  All tracked extensions already installed"
	fi
	unset _installed _count _ext
else
	echo "  ⚠️  'code' CLI not found — skipped extension install"
	SETUP_WARNINGS+=("VS Code 'code' CLI not on PATH — extensions were not installed.")
fi

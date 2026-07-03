#!/usr/bin/env bash
# Configures macOS system preferences and ensures Zsh is the default shell.
#
# Shell: switches the default shell to /bin/zsh if it isn't already. Requires
# a terminal restart to take effect.
#
# Home alias: if LEGACY_USERNAME is set in config.sh, ensures /Users/<name>
# exists as a symlink to the active home directory, so stale tooling that
# references an old username still resolves. Skipped when unset.
#
# Preferences: applies custom macOS defaults from ~/.osx (symlinked from the
# repo's .osx file by the symlinks step), the NSGlobalDomain snapshot captured
# by `macdump` (macos/GlobalDefaults.plist), and the menu bar / Control Center
# snapshot captured by `menudump` (macos/ControlCenter*.plist) when present.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$REPO/config.sh" ] && source "$REPO/config.sh"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  🖥️  macOS"
echo "══════════════════════════════════════"
echo ""

#
# Check the actual login shell rather than $SHELL, which reflects the parent
# process running this script and would trigger a needless chsh password prompt.
#
_login_shell="$(dscl . -read "/Users/$(whoami)" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$_login_shell" != "/bin/zsh" ]; then
	echo "  Switching default shell to zsh..."
	chsh -s /bin/zsh
	echo "  ✅ Default shell set to zsh (restart terminal)"
else
	echo "  ⏭️  Zsh is already the default shell"
fi
unset _login_shell

# Legacy username alias: ensure /Users/$LEGACY_USERNAME resolves (opt-in via config.sh)
if [ -n "${LEGACY_USERNAME:-}" ]; then
	_alias="/Users/$LEGACY_USERNAME"
	if [ -e "$_alias" ] || [ -L "$_alias" ]; then
		echo "  ⏭️  $_alias already exists"
	else
		echo "  Creating $_alias symlink (sudo)..."
		sudo ln -s "$HOME" "$_alias"
		echo "  ✅ Symlinked $_alias → $HOME"
	fi
	unset _alias
fi

if [ -f "$REPO/macos/GlobalDefaults.plist" ]; then
	echo "  Importing global defaults snapshot (from macdump)..."
	defaults import NSGlobalDomain "$REPO/macos/GlobalDefaults.plist"
	echo "  ✅ Global defaults imported"
fi

if [ -f "$REPO/macos/ControlCenter.byhost.plist" ]; then
	echo "  Importing menu bar / Control Center layout (from menudump)..."
	defaults -currentHost import com.apple.controlcenter "$REPO/macos/ControlCenter.byhost.plist"
	defaults import com.apple.controlcenter "$REPO/macos/ControlCenter.plist"
	defaults import com.apple.TextInputMenu "$REPO/macos/TextInputMenu.plist"
	killall ControlCenter 2>/dev/null
	echo "  ✅ Menu bar layout imported"
fi

echo "  Applying macOS preferences..."
bash ~/.osx
echo "  ✅ Preferences applied"

# Set Chrome as the default browser once it's installed. macOS may show a
# one-time confirmation dialog the first time, which has to be approved by hand.
if [ -d "/Applications/Google Chrome.app" ] && command -v defaultbrowser &>/dev/null; then
	if defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -B1 'LSHandlerURLScheme = https;' | grep -q 'com.google.chrome'; then
		echo "  ⏭️  Chrome is already the default browser"
	else
		echo "  Setting Chrome as the default browser..."
		defaultbrowser chrome
		echo "  ✅ Default browser set to Chrome (approve the macOS prompt if one appears)"
	fi
fi

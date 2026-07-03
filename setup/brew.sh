#!/usr/bin/env bash
# Installs Homebrew (if missing) and packages from Brewfile.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  🍺 Homebrew"
echo "══════════════════════════════════════"
echo ""

# Xcode Command Line Tools are a prerequisite for Homebrew
if ! xcode-select -p &>/dev/null; then
	echo "  Installing Xcode Command Line Tools (a GUI prompt will appear)..."
	xcode-select --install
	echo "  ⏳ Re-run 'make setup' once the Command Line Tools finish installing."
	exit 1
fi

# Install Homebrew if not present
if ! command -v /opt/homebrew/bin/brew &>/dev/null; then
	echo "  Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval "$(/opt/homebrew/bin/brew shellenv)"
	echo "  ✅ Installed"
else
	_brew_ok=true
fi

# Trust every tap listed in the Brewfile so bundle install won't prompt when HOMEBREW_REQUIRE_TAP_TRUST is set.
if [ -f "$REPO/Brewfile" ]; then
	_taps=$(grep '^tap ' "$REPO/Brewfile" | sed -E 's/^tap "([^"]+)".*/\1/')
	if [ -n "$_taps" ]; then
		# shellcheck disable=SC2086
		/opt/homebrew/bin/brew trust --tap $_taps &>/dev/null
	fi
	unset _taps
fi

# Install packages from Brewfile (skip if all already installed). Output is
# left visible so progress, sudo prompts, and Mac App Store prompts are seen.
if [ -f "$REPO/Brewfile" ]; then
	if /opt/homebrew/bin/brew bundle check --file="$REPO/Brewfile" &>/dev/null; then
		_bundle_ok=true
	else
		echo "  Installing packages from Brewfile (may take a while)..."
		echo ""
		if /opt/homebrew/bin/brew bundle install --file="$REPO/Brewfile" --no-upgrade --verbose; then
			echo ""
			echo "  ✅ Packages installed"
			date +%s > ~/.brewdump_last

		else
			echo ""
			echo "  ⚠️  Some Brewfile packages failed to install (see output above)"
			SETUP_WARNINGS+=("Some Brewfile packages failed to install — see the Homebrew output above.")
		fi
	fi
fi

# When nvm is available, install Node.js LTS (if missing) and default new shells to it
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
if command -v nvm &>/dev/null; then
	if [ "$(nvm version 'lts/*')" = "N/A" ]; then
		echo "  Installing Node.js LTS via nvm..."
		nvm install --lts
		echo "  ✅ Node.js LTS installed"
	else
		_node_ok=true
	fi
	nvm alias default 'lts/*' &>/dev/null
else
	_node_ok=true
fi

# Single skip message if everything was already in place
if [ "$_brew_ok" = true ] && [ "$_bundle_ok" = true ] && [ "$_node_ok" = true ]; then
	echo "  ⏭️  Everything up to date"
fi
unset _brew_ok _bundle_ok _node_ok

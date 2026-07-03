#!/usr/bin/env bash
# Sets up git identity switching between work and personal accounts.
#
# Identity switching (mode function):
#   Resolves SSH signing keys from 1Password and generates
#   zsh/functions/mode.sh from its template. The mode function
#   lets you switch between work and personal git identities.
#
# Default identity:
#   Creates ~/.gitconfig.local with the work identity.
#   Use `mode home` to switch to personal.
#

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  🔑 Git Identity"
echo "══════════════════════════════════════"
echo ""

# Load user config
if [ ! -f "$REPO/config.sh" ]; then
	echo "  ⏭️  No config.sh — skipped (copy config.sh.example to config.sh, or register a plugin that provides one)"
	SETUP_WARNINGS+=("Git identity not configured — no config.sh present.")
	return 0 2>/dev/null || exit 0
fi
source "$REPO/config.sh"

# Resolve signing keys from 1Password (each independently)
work_key=$(/opt/homebrew/bin/op read --account "$WORK_1PW_ACCOUNT" "$WORK_1PW_KEY" 2>/dev/null)
personal_key=$(/opt/homebrew/bin/op read --account "$PERSONAL_1PW_ACCOUNT" "$PERSONAL_1PW_KEY" 2>/dev/null)

if [ -z "$work_key" ]; then
	echo "  ⚠️  Could not resolve work signing key (op account: $WORK_1PW_ACCOUNT)"
	echo "     Sign in with: op signin --account $WORK_1PW_ACCOUNT"
fi
if [ -z "$personal_key" ]; then
	echo "  ⚠️  Could not resolve personal signing key (op account: $PERSONAL_1PW_ACCOUNT)"
	echo "     Sign in with: op signin --account $PERSONAL_1PW_ACCOUNT"
fi

# Generate mode function with whichever keys are available. Modes whose key is
# missing will produce a gitconfig.local without a signingkey when invoked.
sed \
	-e "s|{{GIT_USER_NAME}}|$GIT_USER_NAME|g" \
	-e "s|{{WORK_EMAIL}}|$WORK_EMAIL|g" \
	-e "s|{{PERSONAL_EMAIL}}|$PERSONAL_EMAIL|g" \
	-e "s|{{WORK_SIGNING_KEY}}|$work_key|g" \
	-e "s|{{PERSONAL_SIGNING_KEY}}|$personal_key|g" \
	-e "s|{{WORK_1PW_ACCOUNT}}|$WORK_1PW_ACCOUNT|g" \
	-e "s|{{PERSONAL_1PW_ACCOUNT}}|$PERSONAL_1PW_ACCOUNT|g" \
	"$REPO/templates/mode.sh.template" > "$REPO/zsh/functions/mode.sh"
echo "  ✅ Generated mode function"

# Generate allowed_signers with whichever keys are available
mkdir -p ~/.ssh
{
	[ -n "$work_key" ] && echo "$WORK_EMAIL $work_key"
	[ -n "$personal_key" ] && echo "$PERSONAL_EMAIL $personal_key"
} > ~/.ssh/allowed_signers
echo "  ✅ Generated allowed_signers"

# Default git identity: prefer work, fall back to personal
if [ -n "$work_key" ]; then
	default_email="$WORK_EMAIL"
	default_key="$work_key"
	default_label="work"
elif [ -n "$personal_key" ]; then
	default_email="$PERSONAL_EMAIL"
	default_key="$personal_key"
	default_label="personal"
fi

if [ -n "$default_key" ]; then
	cat > ~/.gitconfig.local <<EOF
[user]
	name = $GIT_USER_NAME
	email = $default_email
	signingkey = $default_key

[gpg]
	format = ssh

[gpg "ssh"]
	program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
	allowedSignersFile = ~/.ssh/allowed_signers
EOF
	echo "  ✅ Set default identity ($default_label)"
else
	echo "  ⚠️  Skipped writing ~/.gitconfig.local — no signing keys available"
	SETUP_WARNINGS+=("Git commit signing not configured — sign in to 1Password (op signin) and re-run 'make setup'.")
fi


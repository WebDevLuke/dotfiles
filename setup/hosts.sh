#!/usr/bin/env bash
# Syncs /etc/hosts with the canonical copy composed from the repo plus any
# registered plugin fragments (macos/hosts in each).
#
# /etc/hosts is root-owned, so updating it needs sudo. The composed copy is the
# source of truth: if the live file differs, the previous version is backed up
# to /etc/hosts.bak and replaced. To change the entries, edit macos/hosts (or a
# plugin's macos/hosts) and re-run setup.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTS_SRC="$REPO/macos/hosts"

echo ""
echo ""
echo "══════════════════════════════════════"
echo "  🌐 Hosts file"
echo "══════════════════════════════════════"
echo ""

# Repo base + every registered plugin's macos/hosts fragment, in order.
compose_hosts() {
	cat "$HOSTS_SRC"
	for plugin in "$REPO/plugins"/*; do
		[ -f "$plugin/macos/hosts" ] && cat "$plugin/macos/hosts"
	done
}

if [ ! -f "$HOSTS_SRC" ]; then
	echo "  ⚠️  $HOSTS_SRC not found — skipped"
	SETUP_WARNINGS+=("Hosts source ($HOSTS_SRC) missing — /etc/hosts was not synced.")
elif compose_hosts | cmp -s - /etc/hosts; then
	echo "  ⏭️  /etc/hosts already in sync"
else
	echo "  Updating /etc/hosts (sudo)..."
	if sudo cp /etc/hosts /etc/hosts.bak && compose_hosts | sudo tee /etc/hosts >/dev/null; then
		echo "  ✅ /etc/hosts synced (previous version saved to /etc/hosts.bak)"
	else
		echo "  ⚠️  /etc/hosts sync failed (sudo needed) — run 'make macos' in a terminal"
		SETUP_WARNINGS+=("/etc/hosts not synced — sudo was unavailable; run 'make macos'.")
	fi
fi

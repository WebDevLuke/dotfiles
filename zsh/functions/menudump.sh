# Snapshot the current menu bar / Control Center layout into the dotfiles.
# Arrange the menu bar how you want in System Settings > Control Center first,
# then run this to capture it. Re-applied on the next `make setup`.
function menudump() {
	local dir="$HOME/git/dotfiles/macos"

	if [ ! -d "$dir" ]; then
		echo "menudump: $dir not found"
		return 1
	fi

	defaults -currentHost export com.apple.controlcenter "$dir/ControlCenter.byhost.plist" || return 1
	defaults export com.apple.controlcenter "$dir/ControlCenter.plist" || return 1
	defaults export com.apple.TextInputMenu "$dir/TextInputMenu.plist" || return 1

	echo "menudump: snapshotted menu bar state to macos/ (ControlCenter + TextInputMenu)"
}

# Sync the current macOS Dock app order into macos/.osx
function dockdump() {
	local osx="$HOME/git/dotfiles/macos/.osx"
	local url path a tmp
	local apps=()

	if [ ! -f "$osx" ]; then
		echo "dockdump: $osx not found"
		return 1
	fi

	if ! grep -q '# dock-apps:start' "$osx" || ! grep -q '# dock-apps:end' "$osx"; then
		echo "dockdump: dock-apps markers missing in $osx"
		return 1
	fi

	while IFS= read -r url; do
		path="${url#file://}"
		path="${path%/}"
		path=$(printf '%b' "${path//%/\\x}")
		apps+=("$path")
	done < <(defaults read com.apple.dock persistent-apps | grep '"_CFURLString" =' | sed -E 's/.*= "(.*)";/\1/')

	if [ "${#apps[@]}" -eq 0 ]; then
		echo "dockdump: no Dock apps found"
		return 1
	fi

	tmp="$(mktemp)"
	{
		awk '{print} /# dock-apps:start/{exit}' "$osx"
		printf 'dock_apps=(\n'
		for a in "${apps[@]}"; do
			printf '\t"%s"\n' "$a"
		done
		printf ')\n'
		awk '/# dock-apps:end/{f=1} f{print}' "$osx"
	} > "$tmp" && mv "$tmp" "$osx"

	echo "dockdump: synced ${#apps[@]} Dock apps to macos/.osx"
}

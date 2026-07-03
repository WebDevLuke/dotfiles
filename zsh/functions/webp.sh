function webp() {
	cwebp -q 60 "$1" -o "${1/png/webp}"
}

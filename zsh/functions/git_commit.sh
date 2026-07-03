function gc() {
	[ "$1" ] && local msg="$1" || local msg="My automated commit"
	git add -u && git commit -m "$msg" && git push origin HEAD
}

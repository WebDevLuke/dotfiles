# See whats running on a port
function port() {
	sudo lsof -i :"$1"
}

# Force kill a process by PID
function fkill() {
	kill -9 "$1"
}

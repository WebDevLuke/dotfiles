.PHONY: setup doctor macos claude plugin

setup:
	@bash setup.sh

doctor:
	@bash setup/doctor.sh

# Reapply macOS config (preferences, defaults/menu-bar snapshots, hosts) without a full setup
macos:
	@bash setup/macos.sh
	@bash setup/hosts.sh

# Resync Claude Code config (agents, skills, hooks) into ~/.claude/ without a full setup
claude:
	@bash setup/claude.sh

# Register a private plugin repo and apply it. Usage: make plugin DIR=/path/to/plugin
plugin:
	@bash setup/plugin.sh "$(DIR)"

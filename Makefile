.PHONY: help setup doctor macos claude plugin dump brewdump codedump macdump dockdump menudump brewsnooze

.DEFAULT_GOAL := help

REPO := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

# Plugin-contributed sources merged into `make help` automatically: plugins mirror the repo layout under plugins/<name>/, with make targets in a *.mk fragment (not a full Makefile, to avoid clashing with this one) pulled in via -include, which also lists them in MAKEFILE_LIST for help.
ALIAS_FILES := $(REPO)/zsh/.zsh_aliases $(wildcard $(REPO)/plugins/*/zsh/.zsh_aliases)
FUNC_FILES  := $(wildcard $(REPO)/zsh/functions/*.sh) $(wildcard $(REPO)/plugins/*/zsh/functions/*.sh)
-include $(wildcard $(REPO)/plugins/*/*.mk)

BOLD      := \033[1m
CYAN      := \033[36m
DIM       := \033[90m
RESET     := \033[0m
COL_WIDTH := 13

##@ Setup
help: ## Print all available commands
	@printf "\n$(BOLD)Make targets$(RESET) $(DIM)(run: make <target>)$(RESET)\n"
	@awk 'BEGIN {FS = ":.*?## "} /^##@ / { printf "\n  $(BOLD)%s$(RESET)\n", substr($$0,5); next } /^[a-zA-Z_-]+:.*?## / { printf "    $(CYAN)%-$(COL_WIDTH)s$(RESET) $(DIM)│ %s$(RESET)\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\n$(BOLD)Identity$(RESET) $(DIM)(run in your shell)$(RESET)\n"
	@printf "    $(CYAN)%-$(COL_WIDTH)s$(RESET) $(DIM)│ %s$(RESET)\n" \
		"mode"   "Switch git/1Password identity: mode <work|home|switch|status>" \
		"switch" "Shortcut for 'mode switch' - toggle between work and home"
	@printf "\n$(BOLD)Functions$(RESET) $(DIM)(run in your shell)$(RESET)\n"
	@awk 'FNR==1 { desc="" } /^# / { if (desc=="") desc=substr($$0,3); next } /^(function )?[a-zA-Z_]+\(\) *{/ { name=$$0; sub(/^function /,"",name); sub(/\(\).*/,"",name); if (name !~ /^(dockdump|menudump|mode)$$/) printf "    $(CYAN)%-$(COL_WIDTH)s$(RESET) $(DIM)│ %s$(RESET)\n", name, desc; desc=""; next } { desc="" }' $(FUNC_FILES)
	@printf "\n$(BOLD)Aliases$(RESET) $(DIM)(run in your shell)$(RESET)\n"
	@awk 'FNR==1 { desc="" } /^## / { desc=""; printf "\n  $(BOLD)%s$(RESET)\n", substr($$0,4); next } /^# / { if (desc=="") desc=substr($$0,3); next } /^alias / { name=$$0; sub(/^alias /,"",name); sub(/=.*/,"",name); if (name != "switch") printf "    $(CYAN)%-$(COL_WIDTH)s$(RESET) $(DIM)│ %s$(RESET)\n", name, desc; desc=""; next } { desc="" }' $(ALIAS_FILES)
	@printf "\n"

setup: ## Run the full dotfiles setup
	@bash setup.sh

doctor: ## Check the health of the dotfiles setup
	@bash setup/doctor.sh

macos: ## Reapply macOS config (preferences, defaults/menu-bar snapshots, hosts) without a full setup
	@bash setup/macos.sh
	@bash setup/hosts.sh

claude: ## Resync Claude Code config (agents, skills, hooks) into ~/.claude/ without a full setup
	@bash setup/claude.sh

plugin: ## Register a private plugin repo and apply it. Usage: make plugin DIR=/path/to/plugin
	@bash setup/plugin.sh "$(DIR)"

##@ Snapshots
dump: brewdump macdump dockdump menudump ## Snapshot full system state (brew, code, macos, dock, menu bar) back into the repo

brewdump: ## Regenerate Brewfile from installed packages (also syncs VS Code extensions)
	@brew bundle dump --file=$(REPO)/Brewfile --force --no-vscode --describe
	@date +%s > $$HOME/.brewdump_last
	@$(MAKE) --no-print-directory codedump

codedump: ## Sync installed VS Code extensions into vscode/extensions.txt
	@code --list-extensions > $(REPO)/vscode/extensions.txt
	@echo "Synced $$(wc -l < $(REPO)/vscode/extensions.txt | tr -d ' ') VS Code extensions to vscode/extensions.txt"

macdump: ## Export macOS global defaults into macos/GlobalDefaults.plist
	@defaults export NSGlobalDomain $(REPO)/macos/GlobalDefaults.plist
	@echo "✅ macOS defaults exported"

dockdump: ## Snapshot the current Dock app order into macos/.osx
	@bash -c 'source $(REPO)/zsh/functions/dockdump.sh && dockdump'

menudump: ## Snapshot the menu bar / Control Center layout into macos/
	@bash -c 'source $(REPO)/zsh/functions/menudump.sh && menudump'

brewsnooze: ## Snooze the stale-Brewfile reminder for 30 days
	@date +%s > $$HOME/.brewdump_last
	@echo "Brewfile reminder snoozed for 30 days"

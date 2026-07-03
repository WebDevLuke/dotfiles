################################################################################
# BOILERPLATE
################################################################################

# Load aliases, prompt and functions. (-.N) = files (following symlinks, since the function files are symlinked in), no error if none.
for f in ~/.zsh_aliases ~/.zsh_prompt ~/.zsh_functions/*(-.N); do
	[[ -r "$f" ]] && source "$f"
done

# Don't check mail when opening terminal.
unset MAILCHECK

# Add `~/bin` and `~/.local/bin` to the `$PATH`.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Remind to update Brewfile if stale
[[ -r ~/git/dotfiles/config.sh ]] && source ~/git/dotfiles/config.sh
if [ -f ~/.brewdump_last ]; then
	_last=$(cat ~/.brewdump_last)
	_now=$(date +%s)
	_days=$(( (_now - _last) / 86400 ))
	if [ "$_days" -ge "${BREWDUMP_REMINDER_DAYS:-30}" ]; then
		echo "🍺 Brewfile last updated ${_days} days ago. Run 'brewdump' to sync or 'brewsnooze' to dismiss."
	fi
	unset _last _now _days
else
	echo "🍺 Brewfile has never been synced. Run 'brewdump' to create a snapshot."
fi

# Monthly nudge if the dotfiles repo has fallen behind origin (keeps multiple machines from diverging)
if [ ! -f ~/.dotfiles_check_last ] || [ $(( ($(date +%s) - $(cat ~/.dotfiles_check_last)) / 86400 )) -ge 30 ]; then
	git -C ~/git/dotfiles fetch -q origin 2>/dev/null
	_behind=$(git -C ~/git/dotfiles rev-list --count HEAD..origin/master 2>/dev/null)
	if [ "${_behind:-0}" -gt 0 ]; then
		echo "🔄 Dotfiles repo is ${_behind} commit(s) behind origin. Run 'dotfiles' to update."
	fi
	date +%s > ~/.dotfiles_check_last
	unset _behind
fi

# Set 1Password account based on current git identity
_email=$(git config user.email 2>/dev/null)
case "$_email" in
	"${WORK_EMAIL:-__no_work_email__}") export OP_ACCOUNT="$WORK_1PW_ACCOUNT" ;;
	*) export OP_ACCOUNT="$PERSONAL_1PW_ACCOUNT" ;;
esac
unset _email

# Check 1Password SSH agent is running
if [ ! -S ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ]; then
	echo "🔐 1Password SSH agent not running. Open 1Password and enable the SSH agent in Settings > Developer."
fi

# Adds BREW to path to allow terminal usage via brew command
eval "$(/opt/homebrew/bin/brew shellenv)"

# NVM installed via BREW
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
	autoload -U +X bashcompinit && bashcompinit
	\. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi

# Activate nvm's default (LTS) and put it ahead of Homebrew's node on PATH,
# which vercel-cli pulls in and which would otherwise shadow nvm's version.
if nvm use --silent default >/dev/null 2>&1; then
	export PATH="$NVM_BIN:$PATH"
fi

# Nudge if not on the current LTS version. The remote lookup is a network call, so cache it and refresh at most once a month.
if command -v nvm &>/dev/null && command -v node &>/dev/null; then
	_lts_cache=~/.node_lts_cache
	if [ ! -f "$_lts_cache" ] || [ $(( ($(date +%s) - $(stat -f %m "$_lts_cache")) / 86400 )) -ge 30 ]; then
		_lts_remote=$(nvm version-remote --lts 2>/dev/null)
		[ -n "$_lts_remote" ] && echo "$_lts_remote" > "$_lts_cache"
		unset _lts_remote
	fi
	_current=$(node --version 2>/dev/null)
	_lts=$(cat "$_lts_cache" 2>/dev/null)
	if [ -n "$_lts" ] && [ "$_current" != "$_lts" ]; then
		echo "📦 Not on Node.js LTS (current: $_current, LTS: $_lts). Run 'nvm install --lts && nvm alias default lts/*' to switch."
	fi
	unset _current _lts _lts_cache
fi

################################################################################
# ZSH INTERACTIVE FEATURES
################################################################################

# Native completion system (smarter tab-completion than bash).
autoload -Uz compinit && compinit

# fish-style suggestions from history as you type, and command syntax highlighting.
# Syntax highlighting must be sourced last.
[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
	source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
	source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

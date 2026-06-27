# Aliases. Ported verbatim from bootstrap.sh:601-649.
# OS-specific names: Debian ships these as batcat / fdfind.
if command -v fdfind &>/dev/null; then alias fd='fdfind'; fi
# Pick the real bat binary once, then build cat/bat on top of it so the aliases
# can't chain into a name that doesn't exist on this distro.
if command -v batcat &>/dev/null; then _BAT_BIN='batcat'
elif command -v bat &>/dev/null;  then _BAT_BIN='bat'; fi
if [[ -n "${_BAT_BIN:-}" ]]; then
  alias cat="$_BAT_BIN --style=header --paging=never"
  alias bat="$_BAT_BIN --style=full --paging=auto"
fi
unset _BAT_BIN

# Alpine uses doas, not sudo. If sudo is absent but doas is present, alias it so
# the sudo-based aliases below (ports, please) and muscle-memory keep working.
if ! command -v sudo &>/dev/null && command -v doas &>/dev/null; then
  alias sudo='doas'
fi

# Core
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons'
alias grep='grep --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias disk='ncdu'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias home='cd ~'
alias cdconf='cd ~/.config'
alias zshrc='${EDITOR:-nano} $ZDOTDIR/.zshrc'
alias reload='source $ZDOTDIR/.zshrc'

# Docker
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcp='docker compose pull'
# dprune is MANUAL on purpose (removes volumes) — the cron job never touches volumes
alias dprune='docker system prune -a --volumes'

# System
alias myip='curl -s ifconfig.me'
alias ports='sudo ss -tulpn | grep LISTEN'
alias update='sudo apt update && sudo apt upgrade -y'
alias please='sudo $(fc -ln -1)'
# attach-or-create the 'main' session (matches the SSH auto-launch name)
alias tm='tmux new-session -A -s main'

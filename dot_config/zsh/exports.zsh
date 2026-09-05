# Exports. Ported verbatim from bootstrap.sh:651-655.
# Putting ~/.local/bin first is what makes zoxide / uv / fzf (installed there)
# discoverable — see the ordering note in .zshrc about loading this FIRST.

# Load-once guard. On standard/full scope .zshrc sources this file EARLY (before
# Oh My Zsh loads its plugins). The shared modular loader further down then
# re-sources it — make that a no-op so we don't prepend ~/.local/bin to PATH twice.
[[ -n "$_ZDOTDIR_EXPORTS_LOADED" ]] && return
_ZDOTDIR_EXPORTS_LOADED=1

export PATH="$HOME/.local/bin:$PATH"
export EDITOR='nano'
export VISUAL='nano'


# Exports. Ported verbatim from bootstrap.sh:651-655.
# Putting ~/.local/bin first is what makes zoxide / uv / fzf (installed there)
# discoverable — see the ordering note in .zshrc about loading this FIRST.
export PATH="$HOME/.local/bin:$PATH"
export EDITOR='nano'
export VISUAL='nano'

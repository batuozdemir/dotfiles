# Exports. Ported verbatim from bootstrap.sh:651-655.
# Putting ~/.local/bin first is what makes zoxide / uv / fzf (installed there)
# discoverable — see the ordering note in .zshrc about loading this FIRST.
export PATH="$HOME/.local/bin:$PATH"
export EDITOR='nano'
export VISUAL='nano'

# zsh-ai defaults. The API key is intentionally not stored in this shared repo;
# put it in ~/.config/zsh/zsh-ai.local.zsh, which is sourced below if present.
export ZSH_AI_PROVIDER="openai"
export ZSH_AI_OPENAI_URL="https://api.groq.com/openai/v1/chat/completions"
export ZSH_AI_OPENAI_MODEL="qwen/qwen3.6-27b"
export ZSH_AI_OPENAI_REASONING_EFFORT="none"
export ZSH_AI_TRIGGER=",,"

[[ -r "$ZDOTDIR/zsh-ai.local.zsh" ]] && source "$ZDOTDIR/zsh-ai.local.zsh"

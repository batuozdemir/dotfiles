# Mac-only shell config. Installed only on macOS (see .chezmoiignore) and loaded last
# by .zshrc, after exports, aliases, functions and fzf, so it can override them.
# Homebrew's PATH comes from .zprofile. The XDG paths are the shared ones in .zshenv.

# --- Environment ---
export LANG=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=0
export HOMEBREW_CLEANUP_PERIODIC_FULL_UPGRADE=1
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
# Tools that write into $HOME by default, pointed at XDG paths.
export ANSIBLE_HOME="$XDG_CONFIG_HOME/ansible"
export ANDROID_USER_HOME="$XDG_CONFIG_HOME/android"
export MPLCONFIGDIR="$XDG_CONFIG_HOME/matplotlib"
# npm cache through the environment: the agent sandbox cannot read ~/.npmrc.
export npm_config_cache="$XDG_CACHE_HOME/npm"
export LESSHISTFILE=-                                  # no less history
export WGETRC="$XDG_CONFIG_HOME/wgetrc"                # wget ignores XDG

# --- zsh-ai (~/Workspace/tools/zsh-ai) ---
export ZSH_AI_PROVIDER="openai"
export ZSH_AI_OPENAI_URL="http://aperture.ladon-minor.ts.net/v1/chat/completions" 
export ZSH_AI_OPENAI_MODEL="qwen/qwen3.8-27b"
export ZSH_AI_OPENAI_REASONING_EFFORT="none"
export ZSH_AI_TRIGGER=",,"
[ -f ~/Workspace/tools/zsh-ai/zsh-ai.plugin.zsh ] && source ~/Workspace/tools/zsh-ai/zsh-ai.plugin.zsh

# --- Aliases ---
# The shared cc/ccf/ccs/cch/ccl live in aliases.zsh.
alias cg='claude-gpt'
alias ccp='cd ~/phora && cc'
alias ccw='cd ~/Workspace && cc'
alias fd='fd --no-ignore-vcs'
alias rg='rg --no-ignore-vcs'
alias cleands='find . \( -name ".DS_Store" -o -name "._*" \) -type f -delete'
alias dcub='docker compose up -d --build'
alias update='brew update && brew upgrade && brew cleanup' # Adapted for Mac
alias wakepve='wakeonlan -i 10.0.0.255 34:5a:60:37:15:3f'
alias pve='ssh pve'
alias yt="yt-dlp -f 'bestvideo[ext=mp4][height<=1080]+bestaudio[ext=m4a]/best[ext=mp4][height<=1080]' --merge-output-format mp4"
alias yta="yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0"
alias repomix="npx repomix"
alias build-epublite='cd /Users/batumbp/Workspace/projects/ebook-reader-app && xcodebuild -project EpubLite.xcodeproj -scheme EpubLite -configuration Debug -derivedDataPath DerivedData CONFIGURATION_BUILD_DIR="$PWD" build'
alias wispr='python3 ~/phora/projeler/wispr-obsidian-koprusu/senkron.py'
unalias ports 2>/dev/null   # the shared one uses Linux ss

# --- Functions ---
# --- Ghostty Fix ---
# e.g. fix-ghostty user@192.168.1.50
# e.g. fix-ghostty vps-az-1
function fix-ghostty() {
  local host="$1"
  if [ -z "$host" ]; then
    echo "Usage: fix-ghostty <host>"
    return 1
  fi
  echo "📦 Compiling terminfo..."
  infocmp -x xterm-ghostty | ssh "$host" "cat > /tmp/xterm-ghostty.info"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to upload terminfo. Check connection."
    return 1
  fi
  echo "🔑 Installing system-wide (requires sudo)..."
  ssh -t "$host" "sudo tic -x /tmp/xterm-ghostty.info && rm /tmp/xterm-ghostty.info && echo '✅ Done!'"
}

# --- LibreOffice PDF Conversion ---
LO_BIN="/Applications/LibreOffice.app/Contents/MacOS/soffice"

function to_pdf() {
    if [[ -z "$1" ]]; then
        echo "Usage: to_pdf <filename1> [filename2] ..."
        return 1
    fi 
    echo "Converting files to PDF..."
    "$LO_BIN" --headless --convert-to pdf "$@"
}

function convert_all_docs() {
    echo "Looking for .doc, .docx, .ppt, and .pptx files..."
    "$LO_BIN" --headless --convert-to pdf *.doc*(N) *.ppt*(N)
    echo "Batch conversion complete."
}


# Voice recorder. `rc` toggles, `rc status` reports. The recording keeps running
# after the terminal closes, and the same implementation backs the Raycast
# hotkey and the on-sleep hook, so there is only ever one behaviour.
# See ~/Workspace/tools/mac/README.md.
rc() {
  ~/Workspace/tools/mac/bin/recorder.sh "${1:-toggle}"
}


# Claude Code on GPT models through CLIProxyAPI on general-lxc. The settings load
# in a subshell, so this terminal and a plain `claude` stay on the claude.ai login.
# Arguments pass through: claude-gpt --model fable
claude-gpt() {
  ( source ~/.config/cliproxyapi/claude-gpt.env && claude "$@" )
}

# `cmux ssh <host>` names the workspace after the host (cmux alone calls it workspace-N).
# Any other cmux command, or ssh with more arguments, passes through unchanged.
# See ~/Workspace/tools/cmux/README.md §14.
cmux() {
  if [[ $1 == ssh && $# -eq 2 && $2 != -* ]]; then
    command cmux ssh "$2" --name "$2"
  else
    command cmux "$@"
  fi
}

# pull <ssh-host> <remote-path>
#
# Downloads a file or folder from a remote server (defined in ~/.ssh/config)
# into ~/Downloads, and puts a real file reference on the Mac clipboard
# (so Cmd+V works in Finder/Slack/Mail — not just plain text paste).
#
# Usage:
#   pull vps1 ~/file.tar.gz      -> downloads file to ~/Downloads/file.tar.gz
#   pull vps1 ~/folder1/         -> downloads folder to ~/Downloads/folder1/
#
# Pairs with `cpath` on the remote: run `cpath <file/folder>` there to copy
# its absolute path to your Mac clipboard, then paste it as the 2nd arg here.
pull() {
  local host="$1"
  local remote_path="$2"

  if [ -z "$host" ] || [ -z "$remote_path" ]; then
    echo "Usage: pull <ssh-host> <remote-path>"
    return 1
  fi

  remote_path="${remote_path%/}"
  local name
  name=$(basename "$remote_path")

  if ssh "$host" "[ -d \"$remote_path\" ]" 2>/dev/null; then
    echo "📁 Downloading folder: $remote_path"
    mkdir -p ~/Downloads/"$name"
    scp -r "$host:$remote_path/." ~/Downloads/"$name"/
  else
    echo "📄 Downloading file: $remote_path"
    scp "$host:$remote_path" ~/Downloads/
  fi

  # Put a real file reference on the clipboard (not just text) so Cmd+V
  # pastes the actual file into Finder, Slack, Mail, etc.
  osascript -e "set the clipboard to (POSIX file \"$HOME/Downloads/$name\")"
}

# Tab completion and fzf for pull()
_pull() {
  local host cur remote_dir
  local -a candidates

  if (( CURRENT == 2 )); then
    # complete host aliases from ~/.ssh/config
    local -a hosts
    hosts=(${(f)"$(grep -i '^Host ' ~/.ssh/config 2>/dev/null | grep -v '\*' | awk '{print $2}')"})
    compadd -a hosts
    return
  fi

  if (( CURRENT == 3 )); then
    host="${words[2]}"
    cur="${words[3]}"

    # split what's typed so far into "directory so far" + "partial name"
    if [[ "$cur" == */* ]]; then
      remote_dir="${cur%/*}/"
    else
      remote_dir="."
    fi

    candidates=(${(f)"$(ssh -o BatchMode=yes -o ConnectTimeout=3 "$host" "ls -1ap '$remote_dir' 2>/dev/null")"})

    local -a full
    local f
    for f in $candidates; do
      [[ "$f" == "./" || "$f" == "../" ]] && continue
      full+=("${remote_dir}${f}")
    done

    compadd -a full
  fi
}
compdef _pull pull

# --- fzf: also list files that .gitignore hides (overrides fzf.zsh) ---
export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --strip-cwd-prefix"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --no-ignore-vcs --strip-cwd-prefix"
# zoxide's `zi` uses the same eza preview ({2..}: zoxide passes "score path").
export _ZO_FZF_OPTS="--height 40% --layout=reverse --border --preview 'eza --tree --color=always {2..} | head -200'"

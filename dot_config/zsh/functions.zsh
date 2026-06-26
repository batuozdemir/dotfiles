# Shell functions. Ported verbatim from bootstrap.sh:657-685.

# Copy a file's contents to the *local* clipboard over SSH via OSC 52.
# Usage: osc filename.txt   (or pipe:  cmd | osc)
osc() {
  local content
  if [ -t 0 ]; then
    content=$(base64 -w0 "$1" 2>/dev/null || base64 -i "$1")
  else
    content=$(base64 -w0 2>/dev/null || base64)
  fi
  printf "\x1b]52;c;%s\x07" "$content"
}

# Resolve a path to its absolute form and copy it to the local clipboard (OSC 52).
# Usage: cpath [file-or-folder]   (defaults to the current directory)
cpath() {
  local target="${1:-.}" abspath
  abspath=$(realpath "$target" 2>/dev/null) || { echo "No such file or folder: $target"; return 1; }
  printf "\x1b]52;c;%s\x07" "$(printf '%s' "$abspath" | base64 -w0 2>/dev/null || printf '%s' "$abspath" | base64)"
  echo "Copied: $abspath"
}

# compdef only exists once the completion system is initialised (OMZ does this).
# Guard so --minimal (no compinit) doesn't error on load.
if (( $+functions[compdef] )); then
  compdef _files osc
  compdef _files cpath
fi

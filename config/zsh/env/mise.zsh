# Mise configuration
export MISE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

# Cache `mise activate zsh` output to avoid spawning mise on every shell start.
# Invalidated when the mise binary is newer than the cache.
() {
  local mise_bin
  mise_bin="$(command -v mise)" || return

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/mise-activate.zsh"
  if [[ ! -s $cache || $mise_bin -nt $cache ]]; then
    mkdir -p "${cache:h}"
    # Strip the eager `_mise_hook` call; _mise_hook_precmd still runs before
    # the first prompt, so tool resolution is unaffected.
    "$mise_bin" activate zsh | sed '/^_mise_hook$/d' > "$cache"
  fi
  source "$cache"
}

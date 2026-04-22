# Mise configuration
export MISE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

# Wrapper for cache_source: strip the eager `_mise_hook` line so hook-env
# runs via precmd_functions instead of blocking the shell at source time.
_cache_mise_activate() {
  "$1" activate zsh | sed '/^_mise_hook$/d'
}

() {
  local mise_bin
  mise_bin="$(command -v mise)" || return

  cache_source mise-activate "$mise_bin" -- _cache_mise_activate "$mise_bin"
}

unfunction _cache_mise_activate

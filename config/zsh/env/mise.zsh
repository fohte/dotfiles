# Mise configuration
export MISE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

# The precmd-driven `mise activate zsh` below only runs when a prompt is drawn,
# so one-shot subshells (`zsh -c '<cmd>'`) miss it. Prepend the shims dir so
# mise-managed tools are resolvable without an interactive prompt.
path=("$MISE_DATA_DIR/shims"(N-/) $path)

# Wrapper for cache_source: strip the eager `_mise_hook` line so hook-env
# runs via precmd_functions instead of blocking the shell at source time.
_cache_mise_activate() {
  "$1" activate zsh | sed '/^_mise_hook$/d'
}

() {
  local mise_bin
  mise_bin="$(command -v mise)" || return

  cache_source mise-activate "$mise_bin" -- _cache_mise_activate "$mise_bin" || return

  # mise's aqua backend doesn't shim every tool (e.g. gh), so PATH still
  # lacks them until the precmd hook above runs. Run it directly in
  # non-interactive shells since there's no prompt to protect from blocking.
  [[ -o interactive ]] || _mise_hook
}

unfunction _cache_mise_activate

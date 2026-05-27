# Mise configuration
export MISE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

# Ensure mise-managed tools are resolvable in non-interactive shells (e.g.
# Claude Code's Bash subshells). The precmd-driven `mise activate zsh` below
# only runs when a prompt is drawn, so subshells that exec a single command
# and exit miss it; without shims on PATH, `node`/`pnpm`/etc. fall back to
# Homebrew, which breaks corepack pnpm under Node 25.
path=("$MISE_DATA_DIR/shims"(N-/) $path)

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

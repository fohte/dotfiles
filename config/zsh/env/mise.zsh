# Mise configuration
export MISE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

# `mise activate` puts this on PATH as well; the explicit prepend keeps shimmed
# tools resolvable in shells that never reach the activate below.
path=("$MISE_DATA_DIR/shims"(N-/) $path)

() {
  local mise_bin
  mise_bin="$(command -v mise)" || return

  # Deliberately not routed through cache_source, unlike the other init blocks:
  # `mise activate` tailors its output to the environment it runs in. It emits
  # deactivation lines and a literal `export PATH=...` only when it detects an
  # already-active session, so a cached copy replays whichever state the
  # generating shell happened to be in — a stale PATH baked into every later
  # shell, or an inherited __MISE_SESSION left uncleared, which makes the
  # hook-env below a no-op and leaves tools missing from PATH. Running it
  # directly costs ~10ms.
  #
  # The activate output ends with an eager `_mise_hook` that populates PATH.
  # mise pairs it with an __MISE_ZSH_ACTIVATE_PATH snapshot and skips the first
  # precmd hook-env whenever the shell still matches it, so stripping that call
  # to defer the work leaves PATH without non-shimmed tools until the second
  # prompt.
  eval "$("$mise_bin" activate zsh)"
}

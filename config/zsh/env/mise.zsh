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
  # hook-env below a no-op and leaves tools missing from PATH.
  #
  # The activate output ends with an eager `_mise_hook` that populates PATH.
  # mise pairs it with an __MISE_ZSH_ACTIVATE_PATH snapshot and skips the first
  # precmd hook-env whenever the shell still matches it, so stripping that call
  # to defer the work leaves PATH without non-shimmed tools until the second
  # prompt.
  eval "$("$mise_bin" activate zsh)"

  # Everything below reaches into names that come from the activate output above.
  # Bail loudly if a future mise renames them: `add-zsh-hook -d` on an unknown
  # name succeeds silently, so the per-prompt exec would quietly come back, and
  # the wrapper would shadow `mise` with a call to a _mise_orig that never got
  # defined.
  if ((!($+functions[_mise_hook_precmd] && $+functions[_mise_hook] && $+functions[mise]))); then
    print -u2 'mise.zsh: mise activate no longer defines the hooks this file adjusts'
    return
  fi

  # `hook-env` execs the mise binary, and the precmd hook pays that on every
  # prompt regardless of whether anything changed. Dropping it also drops the one
  # thing chpwd and the wrapper below cannot see: a config file rewritten without
  # leaving the directory, as `git checkout` does. Run `_mise_hook` by hand there.
  add-zsh-hook -d precmd _mise_hook_precmd

  # Only _mise_hook_precmd reads these, and mise exports them, so leaving them
  # set would hand a stale PATH snapshot to every child process.
  unset __MISE_ZSH_ACTIVATE_PATH __MISE_ZSH_ACTIVATE_ENV

  # chpwd alone would leave `mise use` and friends unapplied until the next `cd`,
  # so wrap the function mise installs and refresh from there too.
  functions -c mise _mise_orig
  mise() {
    _mise_orig "$@"
    local ret=$?
    # Listing the read-only subcommands rather than the mutating ones keeps the
    # failure asymmetric: a subcommand mise adds later costs one extra hook-env
    # instead of silently leaving a stale environment behind. `deactivate` and
    # `shell` are excluded because _mise_orig already evals their output.
    case "$1" in
      '' | ls | list | ls-remote | where | which | env | e | exec | x | run | r | \
        watch | w | outdated | doctor | dr | version | v | --version | search | \
        tool | latest | tasks | t | registry | bin-paths | completion | help | \
        deactivate | shell | sh) ;;
      *)
        if [[ " $* " != *' --help '* && " $* " != *' -h '* ]]; then
          _mise_hook
        fi
        ;;
    esac
    return $ret
  }
}

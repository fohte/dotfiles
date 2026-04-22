# Generate-on-demand cache of command output, invalidated when any watched
# file (typically the generating binary) is newer than the cache.
#
# Usage: cache_source <name> <watch-file>... -- <cmd> [args...]
#
# The command is run with direct argv (no eval), so shell metacharacters in
# args are not reinterpreted. For pipelines or redirections, wrap them in
# a shell function and pass the function name as <cmd>.
cache_source() {
  # Do not use `emulate -L zsh` / LOCAL_OPTIONS here: the sourced cache is
  # allowed to set global shell options (e.g. starship init runs
  # `setopt promptsubst` and relies on it persisting past this function).
  local name="$1"
  shift

  local -a watches
  while (( $# > 0 )) && [[ "$1" != "--" ]]; do
    watches+=("$1")
    shift
  done
  [[ "$1" == "--" ]] && shift

  if (( $# == 0 )); then
    print -u2 "cache_source: missing command after --"
    return 2
  fi

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${name}.zsh"

  local need_regen=1
  if [[ -s $cache ]]; then
    need_regen=0
    local w
    for w in $watches; do
      if [[ -n $w && $w -nt $cache ]]; then
        need_regen=1
        break
      fi
    done
  fi

  if (( need_regen )); then
    mkdir -p "${cache:h}"
    "$@" > "$cache"
  fi
  source "$cache"
}

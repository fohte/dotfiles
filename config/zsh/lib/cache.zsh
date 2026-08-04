# Generate-on-demand cache of command output, invalidated when argv changes or
# when any watched file (typically the generating binary) is newer than the
# cache. The argv key lives in `<cache>.argv` next to the cache itself.
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
  while (($# > 0)) && [[ "$1" != "--" ]]; do
    watches+=("$1")
    shift
  done
  [[ "$1" == "--" ]] && shift

  if (($# == 0)); then
    print -u2 "cache_source: missing command after --"
    return 2
  fi

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${name}.zsh"

  # argv is part of the cache key, recorded alongside the cache. Generators
  # embed the path they were invoked with into their output — starship bakes it
  # into PROMPT — so a cache generated from a different path keeps running that
  # old binary forever. Watch-file mtimes cannot catch this: when argv resolves
  # to another binary, that binary is typically older than the cache.
  # Quote each element before joining, or `--opt 'a b'` and `--opt a b` collapse
  # to the same key. The nesting is required: in a scalar assignment `(q+)` sees
  # the already-joined string and quotes that instead of the elements.
  local stamp="${cache}.argv"
  local key="${(j: :)${(q+)@}}"

  local need_regen=1
  if [[ -s $cache && -f $stamp && "$(< $stamp)" == "$key" ]]; then
    need_regen=0
    local w
    for w in $watches; do
      if [[ -n $w && $w -nt $cache ]]; then
        need_regen=1
        break
      fi
    done
  fi

  if ((need_regen)); then
    # Atomic write: redirecting directly to $cache truncates it, so two
    # shells starting in parallel can interleave their output. Write to a
    # per-PID tmp file and rename — same-FS rename is atomic.
    mkdir -p "${cache:h}"
    local tmp="${cache}.$$.tmp"
    if ! "$@" > "$tmp"; then
      rm -f "$tmp"
      return 1
    fi
    if ! mv -f "$tmp" "$cache"; then
      rm -f "$tmp"
      return 1
    fi
    # Only now that the new output is installed. Stamping any earlier would
    # advertise the new key while the old output is still in place, which is the
    # stale cache this key exists to catch.
    print -r -- "$key" > "$stamp"
  fi
  source "$cache"
}

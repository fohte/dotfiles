#!/bin/bash

# Source this file to run a callback while holding a directory lock.
# A directory lock works on macOS where flock is not available by default.
# Callbacks call lock_temp_file before writing; the cleanup trap removes the
# temporary file and lock on normal exit or signal termination.
with_mkdir_lock() {
  local lock_path="$1"
  shift

  (
    local lock_acquired=false
    local lock_temp_path=""

    # Invoked by callbacks passed to with_mkdir_lock.
    # shellcheck disable=SC2329
    lock_temp_file() {
      lock_temp_path="$(mktemp "$1.XXXXXX")"
    }

    # shellcheck disable=SC2329
    cleanup_lock() {
      local status=$?
      if [[ "$lock_acquired" == true ]]; then
        rm -f "$lock_temp_path" || true
        rmdir "$lock_path" 2> /dev/null || true
      fi
      exit "$status"
    }

    trap cleanup_lock EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    for _ in $(seq 50); do
      if mkdir "$lock_path" 2> /dev/null; then
        lock_acquired=true
        break
      fi
      sleep 0.1
    done

    if [[ "$lock_acquired" != true ]]; then
      echo "error: failed to acquire lock for $lock_path after 5 seconds" >&2
      echo "If the lock is stale, remove it with: rmdir \"$lock_path\"" >&2
      exit 1
    fi

    "$@"
  )
}

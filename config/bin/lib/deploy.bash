#!/usr/bin/env bash
# Deploy helpers sourced by `dot deploy` and `symlinks`.
# Requires $DOTFILES_DIR to be set by the caller.

# --- OS detection ---

pc_env=''
case "$OSTYPE" in
  darwin*) pc_env='macos' ;;
  linux*)
    if grep -q microsoft /proc/version 2> /dev/null; then
      pc_env='wsl'
    else
      pc_env='linux'
    fi
    ;;
  *) pc_env='other' ;;
esac

is_wsl() { [[ $pc_env == wsl ]]; }
is_macos() { [[ $pc_env == macos ]]; }
is_linux() { [[ $pc_env == linux ]]; }

# --- deploy functions ---

log-exec() {
  if is_dryrun; then
    printf '[dryrun] '
  else
    printf '[run] '
  fi
  echo "$@"

  if ! is_dryrun; then
    "$@"
  fi
}

is_dryrun() { test -n "${DRYRUN:-}"; }
is_force() { test -n "${FORCE:-}"; }

sym() {
  src="$1"
  if [[ "$src" != /* ]]; then
    src="$DOTFILES_DIR/$src"
  fi

  dst="$2"
  dst_dir="$(dirname "$dst")"

  if [ ! -d "$dst_dir" ]; then
    log-exec mkdir -p "$dst_dir"
  fi

  if is_force || [ ! -e "$dst" ]; then
    if [ -d "$dst" ]; then
      log-exec rm -r "$dst"
    fi
    log-exec ln -sfnv "$src" "$dst"
  fi
}

match_tag() {
  tag="$1"

  # if the --tags option is not set, all tags are assumed to be specified
  if [ -z "${tags:-}" ]; then
    return 0
  fi

  grep -q -F "$tag" <<< "$tags"
}

# Resolve a role overlay for <src> and symlink it at <dst>, so runtime
# consumers can `source <dst>` instead of spawning `dot role overlay`.
# If no overlay is defined for the current role, <dst> is removed so a
# stale symlink from a previous role doesn't linger.
sym_role_overlay() {
  local src="$1"
  local dst="$2"
  local overlay

  if overlay="$("$DOTFILES_DIR/config/bin/dot-role" overlay "$DOTFILES_DIR/$src" 2> /dev/null)"; then
    sym "$overlay" "$dst"
  elif [ -L "$dst" ] || [ -e "$dst" ]; then
    log-exec rm -f "$dst"
  fi
}

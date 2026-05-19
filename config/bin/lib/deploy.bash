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

# True when the current machine role (see `dot role`) equals <role>.
match_role() {
  [ "$("$DOTFILES_DIR/config/bin/dot-role" get name 2> /dev/null)" = "$1" ]
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

# Symlink a file from the work role's private repository at <dst>. Unlike
# sym_role_overlay (which replaces a base file), this is for tools that
# merge an additional file alongside the base (e.g. armyknife reads every
# YAML under its config dir). On non-work roles, <dst> is removed so a
# stale symlink doesn't linger.
#
# With --stub-on-fallback, an empty file is deployed at <dst> on non-work
# roles instead of removing it. Use this when a consumer (e.g. runok
# `extends:`) requires the file to exist regardless of role.
sym_role_file() {
  local stub_on_fallback=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --stub-on-fallback)
        stub_on_fallback=true
        shift
        ;;
      *) break ;;
    esac
  done

  local src="$1"
  local dst="$2"
  local role_name role_repo dst_dir

  role_name="$("$DOTFILES_DIR/config/bin/dot-role" get name 2> /dev/null)" || role_name=""
  if [ "$role_name" = work ]; then
    role_repo="$("$DOTFILES_DIR/config/bin/dot-role" get repo)"
    sym "$HOME/ghq/github.com/$role_repo/$src" "$dst"
  elif [ "$stub_on_fallback" = true ]; then
    dst_dir="$(dirname "$dst")"
    if [ ! -d "$dst_dir" ]; then
      log-exec mkdir -p "$dst_dir"
    fi
    if [ -L "$dst" ]; then
      log-exec rm -f "$dst"
    fi
    if is_force || [ ! -e "$dst" ]; then
      log-exec touch "$dst"
    fi
  elif [ -L "$dst" ] || [ -e "$dst" ]; then
    log-exec rm -f "$dst"
  fi
}

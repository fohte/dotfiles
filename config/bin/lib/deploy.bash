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

# Link each child directory into a Windows directory with native Windows
# symlinks. WSL's ln -s creates links that Windows programs cannot follow.
sym_windows_dir() {
  local src="$1" dst="$2" win_src win_dst ps_script
  [[ $src == /* ]] || src="$DOTFILES_DIR/$src"

  win_src="$(wslpath -w "$src")"
  win_dst="$(wslpath -w "$dst")"
  # Quote paths as PowerShell single-quoted strings.
  win_src="${win_src//\'/\'\'}"
  win_dst="${win_dst//\'/\'\'}"

  if is_dryrun; then
    echo "[dryrun] link Windows skills from $win_src into $win_dst"
    return
  fi

  ps_script=$(
    cat << 'POWERSHELL'
param([string]$sourceRoot, [string]$destination)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $sourceRoot).Path.TrimEnd('\')
New-Item -ItemType Directory -Path $destination -Force | Out-Null

function LinkTarget($item) {
  $target = [string]$item.Target
  if ($target.StartsWith('UNC\', [StringComparison]::OrdinalIgnoreCase)) {
    return '\\' + $target.Substring(4)
  }
  return $target
}

$names = @{}
foreach ($skill in Get-ChildItem -LiteralPath $source -Directory) {
  if ($skill.Name -eq 'synced') { continue }
  $names[$skill.Name] = $true
  $link = Join-Path $destination $skill.Name
  $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
  if ($existing) {
    if ($existing.LinkType -eq 'SymbolicLink' -and (LinkTarget $existing) -eq $skill.FullName) {
      continue
    }
    if ($existing.LinkType -ne 'SymbolicLink' -or
        -not (LinkTarget $existing).StartsWith("$source\", [StringComparison]::OrdinalIgnoreCase)) {
      Write-Warning "Keeping existing skill: $link"
      continue
    }
    Remove-Item -LiteralPath $link -Force
  }
  try {
    New-Item -ItemType SymbolicLink -Path $link -Target $skill.FullName -ErrorAction Stop | Out-Null
  } catch {
    throw "Cannot link $link. Enable Windows Developer Mode or run dot deploy from an elevated terminal. $($_.Exception.Message)"
  }
  Write-Output "Linked $($skill.Name)"
}

foreach ($existing in Get-ChildItem -LiteralPath $destination -Force) {
  if ($existing.LinkType -eq 'SymbolicLink' -and
      (LinkTarget $existing).StartsWith("$source\", [StringComparison]::OrdinalIgnoreCase) -and
      -not $names.ContainsKey($existing.Name)) {
    Remove-Item -LiteralPath $existing.FullName -Force
    Write-Output "Removed stale skill: $($existing.Name)"
  }
}
POWERSHELL
  )
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { $ps_script } '$win_src' '$win_dst'"
}

# sym <src> <dst>        link <dst> to <src>
# sym <src>... <dstdir>   link each <src> under <dstdir> by its basename
sym() {
  if [[ ${1:-} == --windows-dir ]]; then
    shift
    sym_windows_dir "$@"
    return
  fi
  if [ $# -gt 2 ]; then
    local dst="${*: -1}"
    local src link
    # An earlier deploy may have linked <dstdir> itself elsewhere; linking into
    # it would then write through that link instead of here.
    if [ -L "$dst" ]; then
      log-exec rm "$dst"
    fi
    for src in "${@:1:$#-1}"; do
      sym "${src%/}" "$dst/$(basename "$src")"
    done
    # A src that no longer exists leaves its link behind dangling.
    for link in "$dst"/*; do
      if [ -L "$link" ] && [ ! -e "$link" ]; then
        log-exec rm "$link"
      fi
    done
    # `dot` runs under `set -e`, so a bare `return` would abort the deploy by
    # leaking the last test's status.
    return 0
  fi

  local src="$1"
  if [[ "$src" != /* ]]; then
    src="$DOTFILES_DIR/$src"
  fi

  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  if [ ! -d "$dst_dir" ]; then
    log-exec mkdir -p "$dst_dir"
  fi

  if is_force || [ ! -e "$dst" ]; then
    if [ -d "$dst" ]; then
      log-exec rm -r "$dst"
    fi
    log-exec ln -sfnv "$src" "$dst"
  elif [ "$(readlink "$dst")" != "$src" ]; then
    echo "[warn] $dst exists but is not a symlink to $src; run 'dot deploy --force' to replace" >&2
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

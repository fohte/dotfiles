#!/bin/bash

set -euo pipefail

DRYRUN="${DRYRUN:-}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_template="$script_dir/pam.d/sudo_local.in"
dst=/etc/pam.d/sudo_local

# Resolve pam_reattach.so via brew so the path tracks the installed keg
# (Apple Silicon vs Intel, formula relocation, etc.).
if ! command -v brew > /dev/null 2>&1; then
  echo "pam.bash: brew not found; skipping" >&2
  exit 0
fi

if ! brew list pam-reattach > /dev/null 2>&1; then
  echo "pam.bash: pam-reattach not installed; run 'brew bundle' first" >&2
  exit 0
fi

pam_reattach_so="$(brew --prefix pam-reattach)/lib/pam/pam_reattach.so"
if [[ ! -e "$pam_reattach_so" ]]; then
  echo "pam.bash: $pam_reattach_so not found" >&2
  exit 1
fi

rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT
sed "s|@PAM_REATTACH_SO@|$pam_reattach_so|g" "$src_template" > "$rendered"

if diff -q "$rendered" "$dst" > /dev/null 2>&1; then
  exit 0
fi

if [[ -n "$DRYRUN" ]]; then
  echo "[dryrun] would update $dst:"
  diff -u "$dst" "$rendered" || true
  exit 0
fi

echo "Updating $dst (requires sudo)..."
sudo install -m 644 -o root -g wheel "$rendered" "$dst"

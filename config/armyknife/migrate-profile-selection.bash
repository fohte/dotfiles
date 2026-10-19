#!/usr/bin/env bash
set -euo pipefail

role="$1"
selection_file="${XDG_CONFIG_HOME:-$HOME/.config}/armyknife/zz-agent-profiles.local.yaml"

[ -f "$selection_file" ] && [ ! -L "$selection_file" ] || exit 0

active_profile="$(yq -r '.agent.active_profile // ""' "$selection_file")"
[ -z "$active_profile" ] || exit 0

legacy_engine="$(yq -r '.agent.launch_profiles.design.engine // ""' "$selection_file")"
case "$role:$legacy_engine" in
  private:codex) profile=codex ;;
  private:claude | work:codex | work:claude) profile=default ;;
  *) exit 0 ;;
esac

printf '[run] a agent profile use %s\n' "$profile"
a agent profile use "$profile"

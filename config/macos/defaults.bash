#!/bin/bash

set -euo pipefail

DRYRUN="${DRYRUN:-}"
changed_apps=()

# Compare current value and apply if different.
# Usage: apply <domain> <key> <type-flag> <value>
# type-flag: -bool, -int, -float, -string
apply() {
  local domain="$1" key="$2" type_flag="$3" value="$4"

  local current
  current="$(defaults read "$domain" "$key" 2> /dev/null || echo "")"

  # Normalize expected value to match `defaults read` output format
  local expected="$value"
  if [[ "$type_flag" == "-bool" ]]; then
    if [[ "$value" == "true" ]]; then
      expected="1"
    else
      expected="0"
    fi
  fi

  if [[ "$current" != "$expected" ]]; then
    if [[ -n "$DRYRUN" ]]; then
      echo "  [dryrun] $domain $key: '$current' -> '$expected'"
      return
    fi
    echo "  $domain $key: '$current' -> '$expected'"
    defaults write "$domain" "$key" "$type_flag" "$value"

    # Track which apps need restart
    local app
    case "$domain" in
      com.apple.dock) app="Dock" ;;
      com.apple.finder) app="Finder" ;;
      *) app="" ;;
    esac
    if [[ -n "$app" ]]; then
      # Deduplicate
      local already=false
      for a in "${changed_apps[@]+"${changed_apps[@]}"}"; do
        if [[ "$a" == "$app" ]]; then
          already=true
          break
        fi
      done
      if ! $already; then
        changed_apps+=("$app")
      fi
    fi
  fi
}

echo "Applying macOS defaults..."

# -- Trackpad --

# Fastest tracking speed (System Settings slider maximum)
apply NSGlobalDomain com.apple.trackpad.scaling -float 5.025641

# Tap to click
apply com.apple.AppleMultitouchTrackpad Clicking -bool true

# Look up & data detectors: three finger tap
apply NSGlobalDomain com.apple.trackpad.threeFingerTapGesture -int 2

# -- Dock --

# Smallest size
apply com.apple.dock tilesize -int 1

# Auto-hide
apply com.apple.dock autohide -bool true

# -- Keyboard --

# Fastest key repeat
apply NSGlobalDomain KeyRepeat -int 2
apply NSGlobalDomain InitialKeyRepeat -int 15

# Disable smart quotes
apply NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Use F1, F2, etc. as standard function keys
apply NSGlobalDomain com.apple.keyboard.fnState -bool true

# -- Appearance --

# Dark mode
apply NSGlobalDomain AppleInterfaceStyle -string Dark

# -- Restart changed apps --

if [[ ${#changed_apps[@]} -gt 0 ]]; then
  echo "Restarting: ${changed_apps[*]}"
  for app in "${changed_apps[@]}"; do
    killall "$app" 2> /dev/null || true
  done
else
  echo "No changes needed."
fi

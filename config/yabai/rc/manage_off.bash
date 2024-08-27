#!/usr/bin/env bash

manage_off() {
  yabai -m rule --add manage=off mouse_follows_focus=off "$@"
}

manage_off subrole="^AXSystemDialog$"       # alert, dialog, etc.
manage_off app='^Ivory$' title='- Compose$' # posting window
manage_off app='^Ivory$' title='^Ivory$'    # media preview

# Preferences for some apps
manage_off app='^System Settings$'
manage_off app='^ChatGPT$' title='^Settings$'
manage_off app='^Arc$' title='^Fohte$' # Settings' title is set to the user's name

# workaround for Picture in Picture not starting when switching tabs in Arc browser
# ref: https://github.com/koekeishiya/yabai/issues/1669
manage_off title="^Picture in Picture$"

manage_off app='^Slack$' title='^Huddle: ' # Slack Huddle

# tiling is not needed for some apps
manage_off app='^BetterTouchTool$'
manage_off app='^Karabiner-Elements$'
manage_off app='^CleanShot X$'

# FIXME: invalid regex pattern '^(?!Notes$).*' for key 'title'
# manage_off app='^Notes$' title='^(?!Notes$).*' # Quick note

# GhostText window
manage_off app='^wezterm-gui$'

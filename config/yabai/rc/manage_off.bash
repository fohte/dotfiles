#!/usr/bin/env bash

manage_off() {
  yabai -m rule --add manage=off mouse_follows_focus=off "$@"
}

manage_off label='system_dialog' subrole="^AXSystemDialog$"    # alert, dialog, etc.
manage_off label='ivory_post' app='^Ivory$' title='- Compose$' # posting window
manage_off label='ivory_preview' app='^Ivory$' title='^Ivory$' # media preview

# Preferences for some apps
manage_off label='system_settings' app='^System Settings$'
manage_off label='chatgpt_settings' app='^ChatGPT$' title='^Settings$'
manage_off label='arc_settings' app='^Arc$' title='^Fohte$' # Settings' title is set to the user's name
manage_off label='fantastical_settings' app='^Fantastical$' title!='^Fantastical$'

# workaround for Picture in Picture not starting when switching tabs in Arc browser
# ref: https://github.com/koekeishiya/yabai/issues/1669
manage_off label='pip' title="^Picture in Picture$"

manage_off label='huddle' app='^Slack$' title='^Huddle: ' # Slack Huddle

# tiling is not needed for some apps
manage_off label='btt' app='^BetterTouchTool$'
manage_off label='karabiner_elements' app='^Karabiner-Elements$'
manage_off label='cleanshot' app='^CleanShot X$'

# FIXME: invalid regex pattern '^(?!Notes$).*' for key 'title'
# manage_off app='^Notes$' title='^(?!Notes$).*' # Quick note

# GhostText window
manage_off label='ghosttext' app='^wezterm-gui$'

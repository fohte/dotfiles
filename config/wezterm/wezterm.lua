local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font 'HackGen35 Console NF'
config.color_scheme = 'Material Darker (base16)'

config.keys = {
  {
    key = 'F3',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = 'F4',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = 'F7',
    action = wezterm.action.ActivateCopyMode,
  },
}

config.window_decorations = 'RESIZE'

return config

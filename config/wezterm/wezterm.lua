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
  {
    key = '|',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '_',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
}

config.window_decorations = 'RESIZE'

local hacky_user_commands = {
  ['new-ghosttext-window'] = function(window, pane, cmd_context)
    local _, _, window = wezterm.mux.spawn_window {
      args = { 'zsh', '-c', 'nvim -c GhostTextStart'},
      cwd = wezterm.home_dir,
    }

    wezterm.GLOBAL.ghosttext_window_id = window:window_id()

    return
  end,
}

wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == 'hacky-user-command' then
    local cmd_context = wezterm.json_parse(value)
    hacky_user_commands[cmd_context.cmd](window, pane, cmd_context)
    return
  end
end)

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  if tab.window_id == wezterm.GLOBAL.ghosttext_window_id then
    return 'GhostText'
  end

  return title
end)

return config

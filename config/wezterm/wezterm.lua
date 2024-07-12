local wezterm = require('wezterm')
local config = {}

config.font = wezterm.font('HackGen35 Console NF')
config.color_scheme = 'Material Darker (base16)'
config.window_background_opacity = 0.9

-- bell is annoying
config.audible_bell = 'Disabled'

config.keys = {
  -- disable zoom
  { key = '+', mods = 'CTRL|SHIFT', action = wezterm.action.DisableDefaultAssignment },
  { key = '_', mods = 'CTRL|SHIFT', action = wezterm.action.DisableDefaultAssignment },
}

-- workaround for the problem that SKK sends CTRL + any keys directly to WezTerm instead of SKK
config.macos_forward_to_ime_modifier_mask = 'SHIFT|CTRL'

config.mouse_bindings = {
  -- Change the default click behavior so that it only selects
  -- text and doesn't open hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection('ClipboardAndPrimarySelection'),
  },

  -- and make CTRL-Click open hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

config.window_decorations = 'RESIZE'
config.enable_tab_bar = false

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

local hacky_user_commands = {
  ['new-ghosttext-window'] = function(window, pane, cmd_context)
    local _, _, window = wezterm.mux.spawn_window({
      args = { 'zsh', '-c', 'nvim -c GhostTextStart' },
      cwd = wezterm.home_dir,
    })

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

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config)
  return tab.tab_index + 1 .. ' ' .. basename(tab.active_pane.current_working_dir)
end)

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  if tab.window_id == wezterm.GLOBAL.ghosttext_window_id then
    return 'GhostText'
  end

  return title
end)

return config

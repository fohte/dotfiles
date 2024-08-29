local lib = require('lib')
local yabai = require('rc/yabai')

local function find_window_id(app_name)
  local result = yabai.run('query --windows')
  if not result.success then
    return nil
  end

  local windows = hs.json.decode(result.output)
  for _, window in ipairs(windows) do
    if window.app == app_name then
      return window.id
    end
  end

  return nil
end

local function defineOpenAppHotkey(mods, key, func)
  hs.hotkey.bind(mods, key, function()
    yabai.with_temp_config({
      focus_follows_mouse = 'off',
      mouse_follows_focus = 'on',
    }, func)
  end)
end

defineOpenAppHotkey({ 'alt' }, '1', function()
  local window_id = find_window_id('WezTerm')
  if window_id == nil then
    hs.application.launchOrFocus('/Applications/WezTerm.app')
  else
    yabai.run('window --focus ' .. window_id)
  end
end)

defineOpenAppHotkey({ 'alt' }, '2', function()
  hs.application.launchOrFocus('/Applications/Arc.app')
end)

defineOpenAppHotkey({ 'alt' }, '3', function()
  hs.application.launchOrFocus('/Applications/Slack.app')
end)

defineOpenAppHotkey({ 'alt' }, '5', function()
  hs.application.launchOrFocus('/Applications/ChatGPT.app')
end)

defineOpenAppHotkey({ 'alt' }, 'o', function()
  hs.application.launchOrFocus('/Applications/Obsidian.app')
end)

defineOpenAppHotkey({ 'alt' }, '8', function()
  hs.application.launchOrFocus('/Applications/Todoist.app')
end)

defineOpenAppHotkey({ 'alt' }, '9', function()
  hs.application.launchOrFocus('/Applications/Fantastical.app')
end)

-- WezTerm の GhostText window を開く
defineOpenAppHotkey({ 'alt' }, '4', function()
  local window_id = find_window_id('wezterm-gui')
  print('Alt-4: ' .. hs.inspect(window_id))

  if window_id == nil then
    hs.execute([[ nohup wezterm start -- zsh -c 'nvim -c GhostTextStart' > /dev/null 2>&1 & ]], true)
  else
    yabai.run('window --focus ' .. window_id)
  end
end)

-- open Obsidian to create a Zettelkasten note
defineOpenAppHotkey({ 'alt' }, 'n', function()
  hs.urlevent.openURL('obsidian://advanced-uri?commandid=quickadd%253Achoice%253A0c5f0598-dc5f-47db-863c-bc867fdc2625')
end)

local lib = require('lib')
local yabai = require('rc/yabai')

local function defineOpenAppHotkey(mods, key, func)
  hs.hotkey.bind(mods, key, function()
    yabai.with_temp_config({
      focus_follows_mouse = 'off',
      mouse_follows_focus = 'on',
    }, func)
  end)
end

defineOpenAppHotkey({ 'alt' }, '1', function()
  local window_id = yabai.find_next_window('WezTerm').id
  if window_id == nil then
    hs.application.launchOrFocus('/Applications/WezTerm.app')
  else
    yabai.run('window --focus ' .. window_id)
  end
end)

defineOpenAppHotkey({ 'alt' }, '2', function()
  hs.application.launchOrFocus('/Applications/Arc.app')
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

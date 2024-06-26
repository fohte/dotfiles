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

hs.hotkey.bind({ 'alt' }, '1', function()
  local window_id = find_window_id('WezTerm')
  print('Alt-1: ' .. hs.inspect(window_id))
  if window_id == nil then
    hs.application.launchOrFocus('/Applications/WezTerm.app')
  else
    yabai.run('window --focus ' .. window_id)
  end
end)

hs.hotkey.bind({ 'alt' }, '2', function()
  hs.application.launchOrFocus('/Applications/Arc.app')
end)

hs.hotkey.bind({ 'alt' }, '3', function()
  hs.application.launchOrFocus('/Applications/Slack.app')
end)

hs.hotkey.bind({ 'alt' }, '5', function()
  hs.application.launchOrFocus('/Applications/ChatGPT.app')
end)

hs.hotkey.bind({ 'alt' }, '6', function()
  hs.application.launchOrFocus('/Applications/Obsidian.app')
end)

hs.hotkey.bind({ 'alt' }, '8', function()
  hs.application.launchOrFocus('/Applications/Todoist.app')
end)

hs.hotkey.bind({ 'alt' }, '9', function()
  hs.application.launchOrFocus('/Applications/Fantastical.app')
end)

-- WezTerm の GhostText window を開く
hs.hotkey.bind({ 'alt' }, '4', function()
  local window_id = find_window_id('wezterm-gui')
  print('Alt-4: ' .. hs.inspect(window_id))

  if window_id == nil then
    hs.execute([[ nohup wezterm start -- zsh -c 'nvim -c GhostTextStart' > /dev/null 2>&1 & ]], true)
  else
    yabai.run('window --focus ' .. window_id)
  end
end)

hs.hotkey.bind({ 'alt' }, '1', function()
  local app = hs.application.find('WezTerm')
  if app then
    local windows = app:allWindows()
    for _, window in ipairs(windows) do
      if window:title() ~= 'GhostText' then
        window:focus()
      end
    end
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
  local app = hs.application.find('WezTerm')
  if app then
    local window = app:findWindow('GhostText')
    if window then
      window:focus()
    end
  end
end)

require('rc/yabai')

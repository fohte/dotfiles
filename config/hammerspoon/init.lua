------------------------------
--- Applications
------------------------------
hs.hotkey.bind({ 'alt' }, '1', function()
  hs.application.launchOrFocus('/Applications/WezTerm.app')
end)

hs.hotkey.bind({ 'alt' }, '2', function()
  hs.application.launchOrFocus('/Applications/Arc.app')
end)

hs.hotkey.bind({ 'alt' }, '5', function()
  -- try to launch Claude, fallback to ChatGPT if not installed
  if hs.fs.attributes('/Applications/Claude.app') then
    hs.application.launchOrFocus('/Applications/Claude.app')
  else
    hs.application.launchOrFocus('/Applications/ChatGPT.app')
  end
end)

hs.hotkey.bind({ 'alt' }, 'o', function()
  hs.application.launchOrFocus('/Applications/Obsidian.app')
end)

hs.hotkey.bind({ 'alt' }, '8', function()
  hs.application.launchOrFocus('/Applications/Todoist.app')
end)

hs.hotkey.bind({ 'alt' }, '9', function()
  hs.application.launchOrFocus('/Applications/Fantastical.app')
end)

------------------------------
--- Window Management
------------------------------
-- disable animation
hs.window.animationDuration = 0

-- maximize/restore window size
local windowSizes = {}
hs.hotkey.bind({ 'ctrl', 'shift' }, 't', function()
  local window = hs.window.focusedWindow()
  local id = window:id()

  if windowSizes[id] then -- restore window size
    window:setFrame(windowSizes[id])
    windowSizes[id] = nil
  else -- maximize window size
    windowSizes[id] = window:frame()
    window:maximize()
  end
end)

-- left half
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Left', function()
  local window = hs.window.focusedWindow()
  local screen = window:screen()
  local frame = screen:frame()
  window:setFrame(hs.geometry.rect(frame.x, frame.y, frame.w / 2, frame.h))
end)

-- right half
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Right', function()
  local window = hs.window.focusedWindow()
  local screen = window:screen()
  local frame = screen:frame()
  window:setFrame(hs.geometry.rect(frame.x + frame.w / 2, frame.y, frame.w / 2, frame.h))
end)

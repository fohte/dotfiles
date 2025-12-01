------------------------------
--- Applications
------------------------------
hs.hotkey.bind({ 'alt' }, '1', function()
  hs.application.launchOrFocus('/Applications/WezTerm.app')
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

-- three-way split
local function get_third_split_position(window, screen)
  local win_frame = window:frame()
  local screen_frame = screen:frame()
  local third_width = screen_frame.w / 3
  local relative_x = win_frame.x - screen_frame.x

  -- tolerance for floating point comparison
  local tolerance = 10

  -- check both position and width to ensure window is in standard three-way split position
  local width_matches = math.abs(win_frame.w - third_width) < tolerance

  if relative_x < tolerance and width_matches then
    return 'left'
  elseif math.abs(relative_x - third_width) < tolerance and width_matches then
    return 'middle'
  elseif math.abs(relative_x - third_width * 2) < tolerance and width_matches then
    return 'right'
  end

  -- return nil if not in standard position
  return nil
end

local function move_third_split(direction)
  return function()
    local window = hs.window.focusedWindow()
    local screen = window:screen()
    local frame = screen:frame()
    local third_width = frame.w / 3

    local position = get_third_split_position(window, screen)

    -- define transitions for each direction
    local transitions = {
      left = {
        right = 'middle',
        middle = 'left',
        left = nil, -- do nothing
      },
      right = {
        left = 'middle',
        middle = 'right',
        right = nil, -- do nothing
      },
    }

    -- initialize to edge if not in standard position
    local next_position = transitions[direction][position] or direction

    if next_position then
      local x_positions = {
        left = frame.x,
        middle = frame.x + third_width,
        right = frame.x + third_width * 2,
      }
      window:setFrame(hs.geometry.rect(x_positions[next_position], frame.y, third_width, frame.h))
    end
  end
end

hs.hotkey.bind({ 'ctrl', 'shift', 'alt' }, 'Left', move_third_split('left'))
hs.hotkey.bind({ 'ctrl', 'shift', 'alt' }, 'Right', move_third_split('right'))

-- move window to previous display
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Up', function()
  local window = hs.window.focusedWindow()
  local screen = window:screen()
  local previousScreen = screen:previous()
  window:moveToScreen(previousScreen)
end)

-- move window to next display
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Down', function()
  local window = hs.window.focusedWindow()
  local screen = window:screen()
  local nextScreen = screen:next()
  window:moveToScreen(nextScreen)
end)

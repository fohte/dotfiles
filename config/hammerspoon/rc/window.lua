local window = {}

-- disable animation
hs.window.animationDuration = 0

-- window sizes for maximize/restore functionality
local windowSizes = {}
local sideWindowTitle = 'tq (Side Window)'

local function usableFrame(screen, win)
  local frame = screen:frame()

  if win:title() == sideWindowTitle then
    return frame
  end

  local tqApplication = hs.application.get('tq')
  if not tqApplication then
    return frame
  end

  local screenID = screen:id()
  local rightEdge = frame.x + frame.w
  local leftInset = 0
  local rightInset = 0
  local tolerance = 10

  for _, candidate in ipairs(tqApplication:visibleWindows()) do
    if candidate:title() == sideWindowTitle and candidate:screen():id() == screenID then
      local candidateFrame = candidate:frame()
      if math.abs(candidateFrame.x - frame.x) <= tolerance then
        leftInset = candidateFrame.w
      elseif math.abs(candidateFrame.x + candidateFrame.w - rightEdge) <= tolerance then
        rightInset = candidateFrame.w
      end
    end
  end

  return hs.geometry.rect(frame.x + leftInset, frame.y, frame.w - leftInset - rightInset, frame.h)
end

local function setFrameWithinBounds(win, bounds, targetFrame)
  win:setFrame(targetFrame)

  local actualFrame = win:frame()
  local rightEdge = bounds.x + bounds.w
  local x = math.max(bounds.x, math.min(actualFrame.x, rightEdge - actualFrame.w))

  if x ~= actualFrame.x then
    win:setFrame(hs.geometry.rect(x, actualFrame.y, actualFrame.w, actualFrame.h))
  end
end

-- maximize or restore window size
function window.toggleMaximize()
  local win = hs.window.focusedWindow()
  local id = win:id()

  if windowSizes[id] then -- restore window size
    win:setFrame(windowSizes[id])
    windowSizes[id] = nil
  else -- maximize window size
    windowSizes[id] = win:frame()
    local screen = win:screen()
    local frame = usableFrame(screen, win)
    setFrameWithinBounds(win, frame, frame)
  end
end

-- move window to left half
function window.moveToLeftHalf()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local frame = usableFrame(screen, win)
  setFrameWithinBounds(win, frame, hs.geometry.rect(frame.x, frame.y, frame.w / 2, frame.h))
end

-- move window to right half
function window.moveToRightHalf()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local frame = usableFrame(screen, win)
  setFrameWithinBounds(win, frame, hs.geometry.rect(frame.x + frame.w / 2, frame.y, frame.w / 2, frame.h))
end

-- get current position in three-way split
local function get_third_split_position(win, frame)
  local win_frame = win:frame()
  local third_width = frame.w / 3
  local relative_x = win_frame.x - frame.x

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

  if win_frame.w < frame.w - tolerance then
    if relative_x < tolerance then
      return 'left'
    elseif math.abs(relative_x - third_width) < tolerance then
      return 'middle'
    elseif math.abs(win_frame.x + win_frame.w - frame.x - frame.w) < tolerance then
      return 'right'
    end
  end

  -- return nil if not in standard position
  return nil
end

-- move window in three-way split
function window.moveThirdSplit(direction)
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local frame = usableFrame(screen, win)
  local third_width = frame.w / 3

  local position = get_third_split_position(win, frame)

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
    setFrameWithinBounds(win, frame, hs.geometry.rect(x_positions[next_position], frame.y, third_width, frame.h))
  end
end

-- move window to previous display
function window.moveToPreviousDisplay()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local previousScreen = screen:previous()
  win:moveToScreen(previousScreen)
end

-- move window to next display
function window.moveToNextDisplay()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local nextScreen = screen:next()
  win:moveToScreen(nextScreen)
end

return window

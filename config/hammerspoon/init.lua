------------------------------
--- IPC (required for `hs` CLI)
------------------------------
require('hs.ipc')

local cliPrefix = hs.fs.attributes('/opt/homebrew') and '/opt/homebrew' or '/usr/local'
if not hs.ipc.cliStatus(cliPrefix) then
  hs.ipc.cliInstall(cliPrefix)
end

------------------------------
--- URL Handlers
------------------------------
local lib = require('lib')

-- hammerspoon:// is reachable from any web page, so sessionId must look like
-- a UUID before it reaches the shell
local UUID_PATTERN = '^'
  .. ('%x'):rep(8)
  .. '%-'
  .. ('%x'):rep(4)
  .. '%-'
  .. ('%x'):rep(4)
  .. '%-'
  .. ('%x'):rep(4)
  .. '%-'
  .. ('%x'):rep(12)
  .. '$'

-- tq (https://tq.fohte.net) opens hammerspoon://tq-focus?sessionId=<id> to
-- jump to a Claude Code session's tmux pane
hs.urlevent.bind('tq-focus', function(_, params)
  local sessionId = params.sessionId
  if not sessionId or not sessionId:match(UUID_PATTERN) then
    print(string.format('tq-focus: rejected sessionId %q', tostring(sessionId)))
    return
  end

  -- shell = true: `a cc focus` shells out to `tmux`, which only resolves
  -- via PATH from the user's shell profile
  lib:run_command(os.getenv('HOME') .. '/.cargo/bin/a cc focus ' .. sessionId, { shell = true })
  hs.application.launchOrFocus('/Applications/Ghostty.app')
end)

------------------------------
--- Applications
------------------------------
local function launchFocusOrCycle(path)
  return function()
    local app = hs.application.frontmostApplication()
    if not (app and app:path() == path) then
      hs.application.launchOrFocus(path)
      return
    end

    local wins = hs.fnutils.filter(app:allWindows(), function(w)
      return w:isStandard() and w:id()
    end)
    -- allWindows() order is not stable, so sort by id to keep cycling deterministic
    table.sort(wins, function(a, b)
      return a:id() < b:id()
    end)
    if #wins < 2 then
      return
    end

    local focused = app:focusedWindow()
    local index = 0
    for i, w in ipairs(wins) do
      if focused and w:id() == focused:id() then
        index = i
      end
    end
    wins[index % #wins + 1]:focus()
  end
end

hs.hotkey.bind({ 'alt' }, '1', launchFocusOrCycle('/Applications/Ghostty.app'))

hs.hotkey.bind({ 'alt' }, '2', launchFocusOrCycle('/Applications/Arc.app'))

hs.hotkey.bind({ 'alt' }, '3', launchFocusOrCycle('/Applications/Slack.app'))

hs.hotkey.bind({ 'alt' }, '5', launchFocusOrCycle('/Applications/Claude.app'))

hs.hotkey.bind({ 'alt' }, 'o', launchFocusOrCycle('/Applications/Obsidian.app'))

hs.hotkey.bind({ 'alt' }, '8', launchFocusOrCycle('/Applications/Todoist.app'))

hs.hotkey.bind({ 'alt' }, '9', launchFocusOrCycle('/Applications/Fantastical.app'))

------------------------------
--- Window Management
------------------------------
local window = require('rc.window')

hs.hotkey.bind({ 'ctrl', 'shift' }, 't', window.toggleMaximize)
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Left', window.moveToLeftHalf)
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Right', window.moveToRightHalf)
hs.hotkey.bind({ 'ctrl', 'shift', 'alt' }, 'Left', function()
  window.moveThirdSplit('left')
end)
hs.hotkey.bind({ 'ctrl', 'shift', 'alt' }, 'Right', function()
  window.moveThirdSplit('right')
end)
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Up', window.moveToPreviousDisplay)
hs.hotkey.bind({ 'ctrl', 'shift' }, 'Down', window.moveToNextDisplay)

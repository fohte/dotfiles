------------------------------
--- Applications
------------------------------
hs.hotkey.bind({ 'alt' }, '1', function()
  hs.application.launchOrFocus('/Applications/Ghostty.app')
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

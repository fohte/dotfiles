local lib = require('lib')

local yabai = lib:run_command('which yabai', { shell = true }).output

local function run_yabai(command, ...)
  return lib:run_command(yabai .. ' -m ' .. command, ...)
end

hs.hotkey.bind({ 'alt' }, 'a', function()
  if run_yabai('config focus_follows_mouse').output == 'disabled' then
    run_yabai('config focus_follows_mouse autoraise')
  else
    run_yabai('config focus_follows_mouse off')
  end
end)

local function bind_yabai(modifiers, key, command)
  if type(command) == 'function' then
    hs.hotkey.bind(modifiers, key, command)
    return
  end

  hs.hotkey.bind(modifiers, key, function()
    run_yabai(command)
  end)
end

-- windows --------------------------------
bind_yabai({ 'ctrl', 'shift' }, 'p', function()
  if not run_yabai('window --focus prev', { silent = true }).success then
    run_yabai('window --focus last')
  end
end)
bind_yabai({ 'ctrl', 'shift' }, 'n', function()
  if not run_yabai('window --focus next', { silent = true }).success then
    run_yabai('window --focus first')
  end
end)

bind_yabai({ 'ctrl', 'shift' }, 'Up', 'window --warp north')
bind_yabai({ 'ctrl', 'shift' }, 'Down', 'window --swap south')
bind_yabai({ 'ctrl', 'shift' }, 'Right', 'window --swap east')
bind_yabai({ 'ctrl', 'shift' }, 'Left', 'window --swap west')

bind_yabai({ 'ctrl', 'shift' }, 't', 'window --toggle zoom-fullscreen')
bind_yabai({ 'ctrl', 'shift' }, 'f', 'window --toggle float')
bind_yabai({ 'ctrl', 'shift' }, '-', 'window --toggle split')

-- resize mode
local resize_mode = hs.hotkey.modal.new({ 'ctrl', 'shift' }, 'r')
local resize_mode_alert = nil

function resize_mode:entered()
  resize_mode_alert = hs.alert.show('Resize mode', 'infinite')
end

function resize_mode:exited()
  if resize_mode_alert then
    hs.alert.closeSpecific(resize_mode_alert)
    resize_mode_alert = nil
  end
end

resize_mode:bind({}, 'escape', function()
  resize_mode:exit()
end)

local resize_delta = 20

local function bind_resize(key, params)
  resize_mode:bind(params.modifiers or {}, key, function()
    run_yabai(string.format('window --resize %s:%d:%d', params.dir, params.x, params.y))
  end)
end

bind_resize('h', { dir = 'left', x = -resize_delta, y = 0 })
bind_resize('h', { modifiers = { 'shift' }, dir = 'left', x = resize_delta, y = 0 })
bind_resize('j', { dir = 'bottom', x = 0, y = resize_delta })
bind_resize('j', { modifiers = { 'shift' }, dir = 'bottom', x = 0, y = -resize_delta })
bind_resize('k', { dir = 'top', x = 0, y = resize_delta })
bind_resize('k', { modifiers = { 'shift' }, dir = 'top', x = 0, y = -resize_delta })
bind_resize('l', { dir = 'right', x = resize_delta, y = 0 })
bind_resize('l', { modifiers = { 'shift' }, dir = 'right', x = -resize_delta, y = 0 })

-- spaces --------------------------------
bind_yabai({ 'cmd', 'ctrl' }, 'p', function()
  if not run_yabai('space --focus prev', { silent = true }).success then
    run_yabai('space --focus last')
  end
end)
bind_yabai({ 'cmd', 'ctrl' }, 'n', function()
  if not run_yabai('space --focus next', { silent = true }).success then
    run_yabai('space --focus first')
  end
end)
bind_yabai({ 'cmd', 'ctrl' }, 'tab', 'space --focus recent')

bind_yabai({ 'cmd', 'ctrl' }, 't', 'space --create')
bind_yabai({ 'cmd', 'ctrl' }, 'w', 'space --destroy')

bind_yabai({ 'cmd', 'ctrl' }, 'v', function()
  if not run_yabai('window --space prev').success then
    run_yabai('window --space last')
  end
end)
bind_yabai({ 'cmd', 'ctrl' }, 'z', function()
  if not run_yabai('window --space next').success then
    run_yabai('window --space first')
  end
end)

-- open mission control to see all spaces
hs.hotkey.bind({ 'cmd', 'ctrl' }, 's', function()
  hs.application.launchOrFocus('Mission Control')
end)

-- display --------------------------------
bind_yabai({ 'alt', 'ctrl' }, 'tab', 'display --focus recent')

bind_yabai({ 'alt', 'ctrl' }, 'v', function()
  if not run_yabai('display --focus prev').success then
    run_yabai('display --focus last')
  end
end)
bind_yabai({ 'alt', 'ctrl' }, 'z', function()
  if not run_yabai('display --focus next').success then
    run_yabai('display --focus first')
  end
end)

return {
  cmd = yabai,
  run = run_yabai,
  run_command = run_command,
}

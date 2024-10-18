local lib = require('lib')

local yabai = lib:run_command('which yabai', { shell = true }).output

local yabai_scripts_dir = os.getenv('HOME') .. '/.config/yabai/scripts'

local function run_scripts(file, cmd, ...)
  return lib:run_command(yabai_scripts_dir .. '/' .. file .. ' ' .. cmd, ...)
end

---@param command string
---@return { success: boolean, output: string, exit_code: number }
local function run_yabai(command, ...)
  return lib:run_command(yabai .. ' -m ' .. command, ...)
end

local function bind_yabai(modifiers, key, command)
  if type(command) == 'function' then
    hs.hotkey.bind(modifiers, key, command)
    return
  end

  hs.hotkey.bind(modifiers, key, function()
    run_yabai(command)
  end)
end

---@param config { key: string, value: string }
---@param func fun(): nil
---@return nil
local function with_temp_config(config, func)
  local current_values = {}

  for key, value in pairs(config) do
    current_values[key] = run_yabai('config ' .. key).output
    if current_values[key] == 'disabled' then
      current_values[key] = 'off'
    end
    run_yabai('config ' .. key .. ' ' .. value)
  end

  func()

  for key, value in pairs(current_values) do
    run_yabai('config ' .. key .. ' ' .. value)
  end
end

local function fetch_windows()
  local result = run_yabai('query --windows')
  if not result.success then
    error('failed to fetch windows')
  end

  return hs.json.decode(result.output)
end

local function find_windows(app_name)
  local windows = fetch_windows()

  local ids = {}

  for _, window in ipairs(windows) do
    if window.app == app_name then
      ids[#ids + 1] = window
    end
  end

  return ids
end

local function find_next_window(app_name)
  local windows = find_windows(app_name)

  for _, window in ipairs(windows) do
    if not window['has-focus'] then
      return window
    end
  end

  return nil
end

bind_yabai({ 'alt' }, '=', 'space --balance')

-- windows --------------------------------
bind_yabai({ 'ctrl', 'shift' }, 'Up', 'window --warp north')
bind_yabai({ 'ctrl', 'shift' }, 'Down', 'window --swap south')
bind_yabai({ 'ctrl', 'shift' }, 'Right', 'window --swap east')
bind_yabai({ 'ctrl', 'shift' }, 'Left', 'window --swap west')

bind_yabai({ 'ctrl', 'shift' }, 't', 'window --toggle zoom-fullscreen')
bind_yabai({ 'ctrl', 'shift' }, '-', 'window --toggle split')
bind_yabai({ 'ctrl', 'shift' }, 'space', 'window --toggle sticky')

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
  local function resize_fn(delta_mult)
    delta_mult = delta_mult or 1
    return function()
      run_yabai(string.format('window --resize %s:%d:%d', params.dir, params.x * delta_mult, params.y * delta_mult))
    end
  end

  resize_mode:bind(params.modifiers or {}, key, resize_fn(), nil, resize_fn(5))
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
bind_yabai({ 'ctrl', 'shift' }, 'v', function()
  if not run_yabai('space --focus prev', { silent = true }).success then
    run_yabai('space --focus last')
  end
end)
bind_yabai({ 'ctrl', 'shift' }, 'z', function()
  if not run_yabai('space --focus next', { silent = true }).success then
    run_yabai('space --focus first')
  end
end)

return {
  cmd = yabai,
  run = run_yabai,
  run_scripts = run_scripts,
  find_windows = find_windows,
  find_next_window = find_next_window,
  with_temp_config = with_temp_config,
}

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

local function run_command(cmd, shell)
  local output, _, _, rc = hs.execute(cmd, shell)

  if rc ~= 0 then
    print('Error (status ' .. hs.inspect(rc) .. '): `' .. cmd .. '`\n' .. output)
  end

  output = output:gsub('\n$', '')

  return output
end

local yabai = run_command('which yabai', true)

hs.hotkey.bind({ 'alt' }, 'a', function()
  local value = run_command(yabai .. ' -m config focus_follows_mouse')
  if value == 'disabled' then
    run_command(yabai .. ' -m config focus_follows_mouse autofocus')
  else
    run_command(yabai .. ' -m config focus_follows_mouse off')
  end
end)

-- Disable animation
hs.window.animationDuration = 0

local lib = require('lib')

-- Right half, 1/3, 2/3
hs.hotkey.bind({ 'alt', 'ctrl' }, 'Right', function()
  lib.window:resizeWindow(function(f, max)
    if hs.geometry.equals(f, lib.window:last_half(max)) then -- 1/2 -> 1/3
      -- debug
      lib.window:copyRect(f, lib.window:last_third(max))
    elseif hs.geometry.equals(f, lib.window:last_third(max)) then -- 1/3 -> 2/3
      lib.window:copyRect(f, lib.window:last_two_thirds(max))
    else                                                          -- 2/3 or any -> 1/2
      lib.window:copyRect(f, lib.window:last_half(max))
    end
  end)
end)

-- Left half, 1/3, 2/3
hs.hotkey.bind({ 'alt', 'ctrl' }, 'Left', function()
  lib.window:resizeWindow(function(f, max)
    if hs.geometry.equals(f, lib.window:first_half(max)) then      -- 1/2 -> 1/3
      lib.window:copyRect(f, lib.window:first_third(max))
    elseif hs.geometry.equals(f, lib.window:first_third(max)) then -- 1/3 -> 2/3
      lib.window:copyRect(f, lib.window:first_two_thirds(max))
    else                                                           -- 2/3 or any -> 1/2
      lib.window:copyRect(f, lib.window:first_half(max))
    end
  end)
end)

-- Maximize
hs.hotkey.bind({ 'alt', 'ctrl' }, 'Up', function()
  lib.window:resizeWindow(function(f, max)
    lib.window:copyRect(f, max)
  end)
end)

-- move the window to the next screen
hs.hotkey.bind({ 'alt', 'ctrl' }, 'n', function()
  local win = hs.window.focusedWindow()
  win:moveToScreen(win:screen():next())
end)

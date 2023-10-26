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

hs.hotkey.bind({ 'alt' }, '6', function()
  hs.application.launchOrFocus('/Applications/Notion.app')
end)

hs.hotkey.bind({ 'alt' }, '8', function()
  hs.application.launchOrFocus('/Applications/Todoist.app')
end)

hs.hotkey.bind({ 'alt' }, '9', function()
  hs.application.launchOrFocus('/Applications/Fantastical.app')
end)

hs.hotkey.bind({ 'alt' }, '0', function()
  hs.application.launchOrFocus('/Applications/Toggl Track.app')
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

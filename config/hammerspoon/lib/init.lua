local lib = {}

---notify error
---@param title string
---@param message string
function lib:notify_error(title, message)
  hs.notify.show('ERROR', title, message)
end

---run shell command
---@param cmd string
---@param params { shell: boolean, silent: boolean }
---@return { success: boolean, output: string, exit_code: number }
function lib:run_command(cmd, params)
  params = params or {}
  local shell = params.shell or false
  local silent = params.silent or false
  local output, _, _, rc = hs.execute(cmd .. ' 2>&1', shell)

  ---@type string
  output = output:gsub('\n$', '')

  if rc ~= 0 and not silent then
    lib:notify_error('$ ' .. cmd, 'output: ' .. output)
  end

  return {
    success = rc == 0,
    output = output,
    exit_code = rc,
  }
end

function lib:followMouseToWindow()
  local win = hs.window.focusedWindow()
  if win then
    local frame = win:frame()
    local center = hs.geometry.rectMidPoint(frame)
    hs.mouse.absolutePosition(center)
  end
end

return lib

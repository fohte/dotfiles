local M = {}

function M.setup(config)
  -- on windows, cannot move the window with `RESIZE` only
  config.window_decorations = 'RESIZE | TITLE'

  config.font_size = 10
end

return M

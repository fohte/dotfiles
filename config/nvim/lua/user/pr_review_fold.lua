local M = {}

function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match('^<!%-%- diff %-%->$') then
    return '>1'
  elseif line:match('^<!%-%- /diff %-%->$') then
    return '<1'
  end
  return '='
end

function M.foldtext()
  local start = vim.v.foldstart
  local end_line = vim.v.foldend
  local count = end_line - start - 1 -- exclude delimiter lines
  return '── diff (' .. count .. ' lines) ──'
end

return M

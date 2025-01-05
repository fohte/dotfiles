local M = {}

-- for ghni command
function M.find_issue_tab(issue_buf)
  local found_tab = -1
  -- get the total number of tabs and loop
  for tabid = 1, vim.fn.tabpagenr('$') do
    vim.cmd('tabnext ' .. tabid)
    -- iterate over all buffers and record if a match is found
    for buf = 1, vim.fn.bufnr('$') do
      if vim.fn.bufexists(buf) == 1 then
        -- check if the buffer name matches the issue buffer (octo://<owner>/<repo>/<issue_number>)
        if vim.fn.bufname(buf) == issue_buf then
          found_tab = tabid
          break
        end
      end
    end
    if found_tab ~= -1 then
      break
    end
  end
  return found_tab
end

return M

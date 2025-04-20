local M = {}

---save the query and result to files
---@param jq_query_path string path to the jq query file
---@param result_path string path to the jq result file
local function create_autocmd_to_save_query_and_result(jq_query_path, result_path)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match('^jq%-filter://') then
          vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), jq_query_path)
        elseif name:match('^jq%-output://') then
          vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), result_path)
        end
      end
    end,
  })
end

local function customize_jq_filter_pane()
  -- focus on the filter window and start the insert mode
  vim.schedule(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match('^jq%-filter://') then
        vim.api.nvim_set_current_win(win)
        vim.cmd('startinsert')
        break
      end
    end
  end)
end

---@param jq_query_path string path to the jq query file
---@param result_path string path to the jq result file
function M.setup(jq_query_path, result_path)
  create_autocmd_to_save_query_and_result(jq_query_path, result_path)
  customize_jq_filter_pane()
end

return M

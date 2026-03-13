vim.opt_local.wrap = true
vim.opt_local.conceallevel = 0

local ns = vim.api.nvim_create_namespace('pr_review_highlight')

local patterns = {
  { pattern = '^<!%-%- thread:.+%-%->$', hl = 'prReviewThreadHeader' },
  { pattern = '^<!%-%- comment:.+%-%->$', hl = 'prReviewCommentDelim' },
  { pattern = '^<!%-%- /comment %-%->$', hl = 'prReviewCommentDelim' },
  { pattern = '^<!%-%- diff %-%->$', hl = 'prReviewDiffDelim' },
  { pattern = '^<!%-%- /diff %-%->$', hl = 'prReviewDiffDelim' },
  { pattern = '^%- %[ %] resolve$', hl = 'prReviewUnresolved' },
  { pattern = '^%- %[x%] resolve$', hl = 'prReviewResolved' },
}

local function apply_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    for _, p in ipairs(patterns) do
      if line:match(p.pattern) then
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
          end_col = #line,
          hl_group = p.hl,
          priority = 200, -- higher than treesitter (100)
        })
        break
      end
    end
  end
end

local bufnr = vim.api.nvim_get_current_buf()
apply_highlights(bufnr)

vim.api.nvim_buf_attach(bufnr, false, {
  on_lines = function(_, buf)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        apply_highlights(buf)
      end
    end)
  end,
})

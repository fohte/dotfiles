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
  local in_comment = false

  for i, line in ipairs(lines) do
    -- track comment regions for border and dimming
    if line:match('^<!%-%- comment:.+%-%->$') then
      in_comment = true
    end

    if in_comment then
      -- dim the entire line (existing comment content)
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        end_col = #line,
        hl_group = 'prReviewCommentBody',
        priority = 200,
      })
      -- left border
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        sign_text = '│',
        sign_hl_group = 'prReviewCommentBorder',
        priority = 200,
      })
    end

    if line:match('^<!%-%- /comment %-%->$') then
      in_comment = false
    end

    -- apply line-level patterns (thread header, delimiters, etc.)
    for _, p in ipairs(patterns) do
      if line:match(p.pattern) then
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
          end_col = #line,
          hl_group = p.hl,
          priority = 210, -- above comment body dimming
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

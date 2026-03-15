vim.opt_local.wrap = true
vim.opt_local.conceallevel = 0

local ns = vim.api.nvim_create_namespace('pr_review_highlight')
local ns_diff = vim.api.nvim_create_namespace('pr_review_diff_highlight')

local patterns = {
  { pattern = '^<!%-%- thread:.+%-%->$', hl = 'prReviewThreadHeader' },
  { pattern = '^<!%-%- comment:.+%-%->$', hl = 'prReviewCommentDelim' },
  { pattern = '^<!%-%- /comment %-%->$', hl = 'prReviewCommentDelim' },
  { pattern = '^<!%-%- diff %-%->$', hl = 'prReviewDiffDelim' },
  { pattern = '^<!%-%- /diff %-%->$', hl = 'prReviewDiffDelim' },
  { pattern = '^%- %[ %] resolve$', hl = 'prReviewUnresolved' },
  { pattern = '^%- %[x%] resolve$', hl = 'prReviewResolved' },
}

--- Resolve a file extension to a treesitter parser name.
--- Returns nil if no parser is available.
local function ext_to_lang(ext)
  local ft = vim.filetype.match({ filename = 'dummy.' .. ext })
  if not ft then
    return nil
  end
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang then
    return nil
  end
  local ok = pcall(vim.treesitter.language.add, lang)
  return ok and lang or nil
end

--- Apply language-aware syntax highlighting to diff regions.
local function apply_diff_highlights(bufnr, lines)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_diff, 0, -1)

  local in_diff = false
  local diff_start = nil
  local diff_regions = {}
  local current_lang = nil

  for i, line in ipairs(lines) do
    local path = line:match('^<!%-%- thread:.+path: ([^ ]+) %-%->')
    if path then
      local ext = path:match('%.([^.:]+):?%d*$') or path:match('%.([^.]+)$')
      current_lang = ext and ext_to_lang(ext) or nil
    end

    if line:match('^<!%-%- diff %-%->$') then
      in_diff = true
      diff_start = i -- 1-indexed, the marker line itself
    elseif line:match('^<!%-%- /diff %-%->$') and in_diff then
      in_diff = false
      table.insert(diff_regions, {
        start_line = diff_start + 1, -- first content line (1-indexed)
        end_line = i - 1, -- last content line (1-indexed)
        lang = current_lang,
      })
    end
  end

  for _, region in ipairs(diff_regions) do
    if region.start_line > region.end_line then
      goto continue
    end

    -- apply diff +/- line highlights
    for li = region.start_line, region.end_line do
      local line = lines[li]
      local prefix = line:sub(1, 1)
      if prefix == '+' then
        vim.api.nvim_buf_set_extmark(bufnr, ns_diff, li - 1, 0, {
          end_col = #line,
          hl_group = 'prReviewDiffAdd',
          priority = 150,
        })
      elseif prefix == '-' then
        vim.api.nvim_buf_set_extmark(bufnr, ns_diff, li - 1, 0, {
          end_col = #line,
          hl_group = 'prReviewDiffDelete',
          priority = 150,
        })
      end
    end

    -- apply language syntax highlighting on top of diff colors
    if not region.lang then
      goto continue
    end

    local query = vim.treesitter.query.get(region.lang, 'highlights')
    if not query then
      goto continue
    end

    -- build code text by stripping the diff prefix (+/-/space) from each line
    local code_lines = {}
    for li = region.start_line, region.end_line do
      table.insert(code_lines, lines[li]:sub(2))
    end
    local code_text = table.concat(code_lines, '\n')

    local ok, parser = pcall(vim.treesitter.get_string_parser, code_text, region.lang)
    if not ok then
      goto continue
    end

    local trees = parser:parse()
    if not trees or not trees[1] then
      goto continue
    end

    for id, node in query:iter_captures(trees[1]:root(), code_text) do
      local sr, sc, er, ec = node:range()
      local hl_group = '@' .. query.captures[id] .. '.' .. region.lang

      -- map string positions back to buffer positions (offset by +1 col for prefix)
      vim.api.nvim_buf_set_extmark(bufnr, ns_diff, region.start_line - 1 + sr, sc + 1, {
        end_row = region.start_line - 1 + er,
        end_col = ec + 1,
        hl_group = hl_group,
        priority = 160, -- above diff color, below delimiter patterns
      })
    end

    ::continue::
  end
end

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

  apply_diff_highlights(bufnr, lines)
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

---Get the git repository root directory
---@return string|nil root Git root directory path or nil if not in a git repo
local function git_root()
  local cmd = { 'git', 'rev-parse', '--show-toplevel' }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout)
end

---Get relative path from git root
---@param file string Absolute file path
---@param root string Git root directory path
---@return string path Relative path from git root
local function get_relative_path(file, root)
  if root and vim.startswith(file, root) then
    return file:sub(#root + 2) -- +2 to remove the trailing slash
  end
  return file
end

---Copy file reference for LLM (format: @path/to/file)
local function copy_llm_ref()
  local root = git_root()
  local file = vim.fn.expand('%:p')

  local path
  if root then
    path = get_relative_path(file, root)
  else
    path = file
  end

  local reference = string.format('@%s', path)
  vim.fn.setreg('+', reference) -- Copy to system clipboard
  vim.notify(string.format('Copied: %s', reference))
end

---Copy file reference with line numbers for LLM (format: @path/to/file#L10-20)
---@param opts table Command options containing line1 and line2
local function copy_llm_ref_with_lines(opts)
  local root = git_root()
  local file = vim.fn.expand('%:p')

  local path
  if root then
    path = get_relative_path(file, root)
  else
    path = file
  end

  local line
  if opts.line1 == opts.line2 then
    line = string.format('#L%d', opts.line1)
  else
    line = string.format('#L%d-%d', opts.line1, opts.line2)
  end

  local reference = string.format('@%s%s', path, line)
  vim.fn.setreg('+', reference) -- Copy to system clipboard
  vim.notify(string.format('Copied: %s', reference))
end

vim.api.nvim_create_user_command('CopyLLMRef', copy_llm_ref, {})
vim.api.nvim_create_user_command('CopyLLMRefWithLines', copy_llm_ref_with_lines, { range = true })

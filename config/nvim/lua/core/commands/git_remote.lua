local function git_root()
  local cmd = { 'git', 'rev-parse', '--show-toplevel' }
  local result = vim.system(cmd, { text = true }):wait()
  return vim.trim(result.stdout)
end

local function git_branch()
  local cmd = { 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }
  local result = vim.system(cmd, { text = true }):wait()
  return vim.trim(result.stdout)
end

local function repository_url()
  local cmd = { 'git', 'config', '--get', 'remote.origin.url' }
  local result = vim.system(cmd, { text = true }):wait()
  return vim.trim(result.stdout)
end

local function open_github_link(opts)
  local root = git_root()
  if root == '' then
    error('This is not a git repository.')
    return
  end

  local branch = opts.args

  if branch == nil or branch == '' then
    branch = git_branch()
  end

  local repo_url = repository_url()
  local file = vim.fn.expand('%')

  local line = ''
  if opts.line1 ~= nil and opts.line2 ~= nil then
    line = string.format('L%d-L%d', opts.line1, opts.line2)
  else
    line = string.format('L%d', vim.fn.line('.'))
  end

  local url = string.format('%s/blob/%s/%s#%s', repo_url, branch, file, line)

  local cmd = { 'open', url }
  vim.system(cmd):wait()
end

vim.api.nvim_create_user_command('OpenGitRemote', open_github_link, { nargs = '?', range = true })

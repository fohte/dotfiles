------------------------------------------------------------
--               .__
--         ___  _|__| ____________   ____
--         \  \/ /  |/     \_  __ \_/ ___\
--          \   /|  |  Y Y  \  | \/\  \___
--           \_/ |__|__|_|  /__|    \___  >
--                        \/            \/    @Fohte
------------------------------------------------------------

if vim.fn.has('vim_starting') == 0 and vim.opt.encoding ~= 'utf-8' then
  vim.opt.encoding = 'utf-8'
end

-- disable python2
vim.g.python_host_prog = ''

if vim.fn.executable('mise') == 1 then
  -- Use a stable python for neovim, not a project-specific one. This avoids
  -- issues where pynvim is not installed for a project's python version.
  -- We mimic the old pyenv logic by finding the latest installed python version
  -- and forcing mise to use it for Neovim's python host.
  local latest_python =
    vim.fn.trim(vim.fn.system('mise ls python --installed | grep "^  python" | awk \'{print $2}\' | sort -V | tail -1'))
  if vim.v.shell_error == 0 and latest_python ~= '' then
    vim.env.MISE_PYTHON_VERSION = latest_python
  end
  vim.g.python3_host_prog = vim.fn.trim(vim.fn.system('mise which python'))
end

vim.env.CACHE = vim.fn.expand('~/.cache')
if vim.fn.isdirectory(vim.env.CACHE) == 0 then
  vim.fn.mkdir(vim.env.CACHE, 'p')
end

-- these should be set before loading lazy
vim.g.mapleader = ' '
vim.g.maplocalleader = '-'

require('core/lazy')

vim.opt.clipboard:prepend({ 'unnamedplus' })

-- disable mouse
vim.opt.mouse = ''

vim.opt.foldmethod = 'manual'
vim.opt.autoread = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true

vim.opt.backspace = { 'indent', 'eol', 'start' }

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrapscan = true

vim.opt.showcmd = true
vim.opt.switchbuf = { 'useopen', 'vsplit' }

vim.opt.inccommand = 'split'

vim.opt.sessionoptions = { 'blank', 'curdir', 'folds', 'tabpages', 'winsize' }

vim.opt.shell = 'bash'

vim.opt.wildoptions = 'pum'

vim.opt.termguicolors = true

vim.opt.number = true
vim.opt.title = true
vim.opt.showmode = false
vim.opt.laststatus = 2

vim.opt.list = true
vim.opt.wrap = false
vim.opt.list = true
vim.opt.listchars:append({ precedes = '<', extends = '>' })

vim.opt.synmaxcol = 1000

vim.opt.completeopt:remove('preview')

vim.opt.previewheight = 7

-- always show the sign column even if no sign have been appeared
-- for example diagnostics of coc.nvim
vim.opt.signcolumn = 'yes'

vim.opt.foldenable = false

require('core/mappings')
require('core/commands')
require('core/filetype')

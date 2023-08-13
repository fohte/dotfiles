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

vim.opt.imd = true

-- disable python2
vim.g.python_host_prog = ''

if vim.fn.executable('pyenv') == 1 then
  vim.g.python3_host_prog = vim.fn.expand('~/.pyenv/shims/python3')
end

vim.env.CACHE = vim.fn.expand('~/.cache')
if vim.fn.isdirectory(vim.env.CACHE) == 0 then
  vim.fn.mkdir(vim.env.CACHE, 'p')
end

vim.g.mapleader = ' '

vim.call('util#source_rc', 'setup_dein.rc.vim')

require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "javascript",
    "lua",
    "tsx",
    "typescript",
    "vim",
  },
  highlight = {
    enable = true,
    disable = {},
  },
}

vim.opt.clipboard:prepend { 'unnamedplus' }

if vim.g.loaded_matchit ~= 1 then
  vim.cmd [[ runtime macros/matchit.vim ]]
end

vim.opt.mouse = 'a'
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

local function my_color_settings()
  vim.cmd 'hi! IncSearch gui=none guibg=#444444 guifg=none'
  vim.cmd 'hi! link Search IncSearch'
  vim.cmd 'hi! Visual guifg=none'
  vim.cmd 'hi! link MatchParen Function'
  vim.cmd 'hi! link CursorLineNr Comment'
end

vim.api.nvim_create_augroup('MyColorSettings', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = 'MyColorSettings',
  callback = my_color_settings
})

vim.opt.termguicolors = true

vim.cmd.colorscheme('material')

vim.opt.number = true
vim.opt.title = true
vim.opt.showmode = false
vim.opt.laststatus = 2

vim.opt.list = true
vim.opt.wrap = false
vim.opt.listchars:append { precedes = '<', extends = '>' }

vim.opt.synmaxcol = 1000

vim.opt.completeopt:remove('preview')

vim.opt.previewheight = 7

-- always show the sign column even if no sign have been appeared
-- for example diagnostics of coc.nvim
vim.opt.signcolumn = 'yes'

vim.opt.foldenable = false

vim.call('util#source_rc', 'mappings.rc.vim')
vim.call('util#source_rc', 'commands.rc.vim')
vim.call('util#source_rc', 'quickfix.rc.vim')

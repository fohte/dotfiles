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

vim.call('util#source_rc', 'edit.rc.vim')
vim.call('util#source_rc', 'view.rc.vim')
vim.call('util#source_rc', 'mappings.rc.vim')
vim.call('util#source_rc', 'commands.rc.vim')
vim.call('util#source_rc', 'quickfix.rc.vim')

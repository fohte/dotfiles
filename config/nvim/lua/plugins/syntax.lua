return {
  {
    'google/vim-jsonnet',
    config = function()
      vim.g.jsonnet_fmt_on_save = 1
    end,
  },
  'plasticboy/vim-markdown',
  'pantharshit00/vim-prisma',
  'hashivim/vim-terraform',
  {
    'tpope/vim-rails',
    ft = 'ruby',
  },
}

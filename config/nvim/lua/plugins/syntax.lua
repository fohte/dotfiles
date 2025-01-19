return {
  {
    'google/vim-jsonnet',
    config = function()
      vim.g.jsonnet_fmt_on_save = 0 -- use efm
    end,
  },
  'pantharshit00/vim-prisma',
  'hashivim/vim-terraform',
  'tokorom/vim-review',
  {
    'tpope/vim-rails',
    ft = 'ruby',
  },
}

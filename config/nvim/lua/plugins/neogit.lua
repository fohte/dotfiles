return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'nvim-telescope/telescope.nvim', -- optional
    'sindrets/diffview.nvim', -- optional
  },
  config = true,
  keys = {
    { '<Leader>t', ':Neogit<CR>', mode = 'n', silent = true },
  },
}

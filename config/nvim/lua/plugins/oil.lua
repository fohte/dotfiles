return {
  'stevearc/oil.nvim',
  commit = '07f80ad645895af849a597d1cac897059d89b686', -- renovate: branch=master
  opts = {},
  dependencies = { { 'nvim-tree/nvim-web-devicons', commit = '6e51ca170563330e063720449c21f43e27ca0bc1' } }, -- renovate: branch=master
  keys = {
    { '<Leader>eo', ':Oil --float<CR>', mode = 'n', silent = true },
  },
  config = function()
    require('oil').setup({
      view_options = {
        show_hidden = true,
      },
      float = {
        -- padding = 20,
      },
      keymaps = {
        ['<C-v>'] = { 'actions.select', opts = { vertical = true } },
        ['<C-s>'] = { 'actions.select', opts = { split = true } },
      },
    })
  end,
}

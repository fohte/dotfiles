return {
  'stevearc/oil.nvim',
  commit = 'bbad9a76b2617ce1221d49619e4e4b659b3c61fc', -- renovate: branch=master
  opts = {},
  dependencies = { { 'nvim-tree/nvim-web-devicons', commit = '3362099de3368aa620a8105b19ed04c2053e38c0' } }, -- renovate: branch=master
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

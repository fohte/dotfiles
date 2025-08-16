return {
  'stevearc/oil.nvim',
  commit = 'bbad9a76b2617ce1221d49619e4e4b659b3c61fc', -- renovate: branch=master
  opts = {},
  dependencies = { { 'nvim-tree/nvim-web-devicons', commit = 'c2599a81ecabaae07c49ff9b45dcd032a8d90f1a' } }, -- renovate: branch=master
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

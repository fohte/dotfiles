return {
  'stevearc/oil.nvim',
  opts = {},
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    { '<Leader>eo', ':Oil --float<CR>', mode = 'n', silent = true },
  },
  config = function()
    require('oil').setup({
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 20,
      },
      keymaps = {
        ['<C-v>'] = { 'actions.select', opts = { vertical = true } },
        ['<C-s>'] = { 'actions.select', opts = { split = true } },
      },
    })
  end,
}

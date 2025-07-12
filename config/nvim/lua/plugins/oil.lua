return {
  'stevearc/oil.nvim',
  commit = '08c2bce8b00fd780fb7999dbffdf7cd174e896fb', -- renovate: branch=master
  opts = {},
  dependencies = { { 'nvim-tree/nvim-web-devicons', commit = '19d6211c78169e78bab372b585b6fb17ad974e82' } }, -- renovate: branch=master
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

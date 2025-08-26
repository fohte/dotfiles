return {
  'stevearc/oil.nvim',
  commit = '07f80ad645895af849a597d1cac897059d89b686', -- renovate: branch=master
  opts = {},
  dependencies = { { 'nvim-tree/nvim-web-devicons', commit = '4ae47f4fb18e85b80e84b729974fe65483b06aaf' } }, -- renovate: branch=master
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

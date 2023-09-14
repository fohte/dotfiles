return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'RRethy/nvim-base16',
  },
  config = function()
    require('lualine').setup({
      options = {
        theme = 'base16',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'filename' },
        lualine_c = {},
        lualine_x = { 'encoding' },
        lualine_y = { 'branch', 'diff', 'location' },
        lualine_z = { 'filetype' },
      },
    })
  end,
}

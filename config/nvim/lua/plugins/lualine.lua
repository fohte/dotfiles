return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' },
    'RRethy/nvim-base16',
  },
  config = function()
    require('lualine').setup({
      options = {
        theme = 'base16',
      },
      sections = {
        lualine_a = {},
        lualine_b = {
          function()
            return vim.fn.expand('%:t')
          end,
          function()
            if vim.bo.modified then
              return ''
            end

            if vim.bo.readonly then
              return ''
            end

            return ''
          end,
        },
        lualine_c = {
          function()
            return vim.fn.expand('%:h')
          end,
        },
        lualine_x = { 'encoding' },
        lualine_y = { 'diff', 'location' },
        lualine_z = { 'filetype' },
      },
      tabline = {
        lualine_a = {
          {
            'tabs',
            mode = 2, -- 2: Shows tab_nr + tab_name
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = { 'branch' },
        lualine_z = {},
      },
    })
  end,
}

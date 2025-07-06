return {
  'mvllow/modes.nvim',
  commit = 'b156d4e4a7c0c7ea9b5609c5d2741c10b8c1d7f5',
  dependencies = {
    'RRethy/nvim-base16',
  },
  config = function()
    local colors = require('base16-colorscheme').colors
    require('modes').setup({
      colors = {
        copy = colors.base0B,
        delete = colors.base08,
        insert = colors.base0D,
        command = colors.base0E,
        visual = colors.base09,
      },
    })
  end,
}

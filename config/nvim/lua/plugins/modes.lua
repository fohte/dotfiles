return {
  'mvllow/modes.nvim',
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

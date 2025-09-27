return {
  'mvllow/modes.nvim',
  commit = '0932ba4e0bdc3457ac89a8aeed4d56ca0b36977a', -- renovate: branch=main
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

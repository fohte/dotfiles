return {
  'mvllow/modes.nvim',
  commit = '57ea7234275eaac54599803db0132706b50e16d4', -- renovate: branch=main
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

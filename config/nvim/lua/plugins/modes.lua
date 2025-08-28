return {
  'mvllow/modes.nvim',
  commit = '69407cef8b8074db0c692abb9216cb123152ef46', -- renovate: branch=main
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

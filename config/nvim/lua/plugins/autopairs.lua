return {
  'windwp/nvim-autopairs',
  commit = '23320e75953ac82e559c610bec5a90d9c6dfa743', -- renovate: branch=master
  config = function()
    require('nvim-autopairs').setup()
  end,
}

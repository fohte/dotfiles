return {
  'windwp/nvim-autopairs',
  commit = '2647cce4cb64fb35c212146663384e05ae126bdf', -- renovate: branch=master
  config = function()
    require('nvim-autopairs').setup()
  end,
}

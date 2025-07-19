return {
  'ray-x/lsp_signature.nvim',
  commit = 'd9c39937e4e0977357530e988aa8940078bb231f', -- renovate: branch=master
  event = 'VeryLazy',
  opts = {},
  config = function(_, opts)
    require('lsp_signature').setup(opts)
  end,
}

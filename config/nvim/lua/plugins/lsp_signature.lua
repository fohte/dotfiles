return {
  'ray-x/lsp_signature.nvim',
  version = 'v0.3.1',
  event = 'VeryLazy',
  opts = {},
  config = function(_, opts)
    require('lsp_signature').setup(opts)
  end,
}

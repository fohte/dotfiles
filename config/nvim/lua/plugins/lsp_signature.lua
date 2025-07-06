return {
  'ray-x/lsp_signature.nvim',
  commit = 'a38da0a61c172bb59e34befc12efe48359884793',
  event = 'VeryLazy',
  opts = {},
  config = function(_, opts)
    require('lsp_signature').setup(opts)
  end,
}

return {
  'ray-x/lsp_signature.nvim',
  commit = '62cadce83aaceed677ffe7a2d6a57141af7131ea', -- renovate: branch=master
  event = 'VeryLazy',
  opts = {},
  config = function(_, opts)
    require('lsp_signature').setup(opts)
  end,
}

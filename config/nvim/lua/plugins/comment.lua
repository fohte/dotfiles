return {
  'numToStr/Comment.nvim',
  version = 'v0.8.0',
  requires = {
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  config = function()
    require('Comment').setup({
      pre_hook = function()
        return require('ts_context_commentstring.internal').calculate_commentstring()
      end,

      mappings = {
        basic = true,
        extra = true,
      },
    })
  end,
}

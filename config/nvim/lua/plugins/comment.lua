return {
  'numToStr/Comment.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
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

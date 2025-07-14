return {
  'numToStr/Comment.nvim',
  commit = 'e30b7f2008e52442154b66f7c519bfd2f1e32acb', -- renovate: branch=master
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

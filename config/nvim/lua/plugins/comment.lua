return {
  'numToStr/Comment.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  init = function()
    -- Skip context-commentstring's backwards-compat autocommand that expects
    -- nvim-treesitter's module system (removed on the main branch).
    vim.g.skip_ts_context_commentstring_module = true
  end,
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

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      -- automatically close end statements (e.g. end in ruby/lua, fi in bash)
      'RRethy/nvim-treesitter-endwise',

      -- keep showing the current context on the top of the window
      -- e.g. if you're inside an if statement, it will show "if ~~" on the top
      'nvim-treesitter/nvim-treesitter-context',

      -- automatically set the commentstring based on the current context
      -- this plugin is used to determine the comment character in comment.nvim
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'bash',
          'javascript',
          'json',
          'json5',
          'lua',
          'ruby',
          'tsx',
          'typescript',
          'vim',
        },
        highlight = { enable = true, disable = {} },
        endwise = { enable = true },
        context = { enable = true },
      })
    end,
  },
}

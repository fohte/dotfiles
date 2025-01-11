return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      -- automatically close end statements (e.g. end in ruby/lua, fi in bash)
      'RRethy/nvim-treesitter-endwise',

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
          'markdown',
          'python',
          'ruby',
          'tsx',
          'typescript',
          'vim',
          'vimdoc',
          'yaml',
        },
        highlight = { enable = true, disable = {} },
        endwise = { enable = true },
        context = { enable = true },
      })

      -- workaround support zsh syntax
      -- ref: https://github.com/nvim-treesitter/nvim-treesitter/issues/655#issuecomment-1470096879
      vim.treesitter.language.register('bash', 'zsh')

      -- use treesitter markdown parser with Octo.nvim buffers
      vim.treesitter.language.register('markdown', 'octo')
    end,
  },
}

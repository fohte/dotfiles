return {
  {
    'nvim-treesitter/nvim-treesitter',
    commit = '42fc28ba918343ebfd5565147a42a26580579482',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      -- automatically close end statements (e.g. end in ruby/lua, fi in bash)
      { 'RRethy/nvim-treesitter-endwise', commit = 'd6cbb83307d516ec076d17c9a33d704ef626ee8c' },

      -- automatically set the commentstring based on the current context
      -- this plugin is used to determine the comment character in comment.nvim
      { 'JoosepAlviste/nvim-ts-context-commentstring', commit = '1b212c2eee76d787bbea6aa5e92a2b534e7b4f8f' },
    },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'bash',
          'javascript',
          'json',
          'json5',
          'jsonc',
          'lua',
          'markdown',
          'python',
          'ruby',
          'rust',
          'typescript',
          'vim',
          'yaml',
          'nix',
          'terraform',
          'hcl',
          'toml',
          'tsx',
          'regex',
          'markdown_inline',
          'comment',
        },
        highlight = { enable = true },
        incremental_selection = { enable = false },
        indent = { enable = true },
        endwise = { enable = true },
        ts_context_commentstring = { enable = true },
      })
    end,
  },
}

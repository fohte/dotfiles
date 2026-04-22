local ensure_installed = {
  'bash',
  'javascript',
  'json',
  'json5',
  'jsonnet',
  'lua',
  'markdown',
  'markdown_inline',
  'python',
  'ruby',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    -- main branch does not support lazy-loading.
    -- ref: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
    lazy = false,
    build = ':TSUpdate',
    dependencies = {
      -- automatically close end statements (e.g. end in ruby/lua, fi in bash)
      { 'RRethy/nvim-treesitter-endwise' },

      -- automatically set the commentstring based on the current context
      -- this plugin is used to determine the comment character in comment.nvim
      { 'JoosepAlviste/nvim-ts-context-commentstring' },
    },
    config = function()
      require('nvim-treesitter').install(ensure_installed)

      -- workaround support zsh syntax
      -- ref: https://github.com/nvim-treesitter/nvim-treesitter/issues/655#issuecomment-1470096879
      vim.treesitter.language.register('bash', 'zsh')

      -- use treesitter markdown parser with Octo.nvim buffers
      vim.treesitter.language.register('markdown', 'octo')

      -- use treesitter markdown parser with PR review thread buffers
      vim.treesitter.language.register('markdown', 'pr_review')

      -- main branch no longer auto-enables highlight/indent per module config;
      -- we start them explicitly on FileType.
      local parser_filetypes = {}
      for _, lang in ipairs(ensure_installed) do
        local fts = vim.treesitter.language.get_filetypes(lang)
        for _, ft in ipairs(fts) do
          parser_filetypes[ft] = true
        end
      end
      -- filetypes registered above that share a parser with another language
      parser_filetypes.zsh = true
      parser_filetypes.octo = true
      parser_filetypes.pr_review = true

      vim.api.nvim_create_autocmd('FileType', {
        pattern = vim.tbl_keys(parser_filetypes),
        callback = function(args)
          -- start() is a no-op if the parser for this buffer is unavailable.
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}

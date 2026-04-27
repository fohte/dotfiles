local context_filetypes = {
  -- Vim's FileType pattern requires an exact match; dotted filetypes do not
  -- expand into their components. core/filetype.lua maps *.tsx to the dotted
  -- filetype `typescript.tsx`, so list it explicitly here.
  'typescript.tsx',
  'typescriptreact',
  'javascriptreact',
  'vue',
  'svelte',
  'astro',
  'html',
  'php',
  'glimmer',
  'handlebars',
  'nu',
}

return {
  {
    'numToStr/Comment.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('Comment').setup({
        mappings = {
          basic = true,
          extra = true,
        },
        pre_hook = function(ctx)
          -- Only consult context-commentstring when its plugin/ file has run
          -- (i.e. lazy.nvim has loaded it via the ft trigger below). Returning
          -- nil falls back to Neovim's native 'commentstring'.
          if vim.g.loaded_ts_context_commentstring ~= 1 then
            return nil
          end
          return require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()(ctx)
        end,
      })
    end,
  },

  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    ft = context_filetypes,
    init = function()
      -- Skip the backwards-compat autocommand that expects nvim-treesitter's
      -- module system (removed on the main branch).
      vim.g.skip_ts_context_commentstring_module = true
    end,
    config = function()
      -- Re-fire FileType so plugin/ts_context_commentstring.lua's autocmd runs
      -- for the buffer that triggered the ft load (the original event already
      -- finished before this plugin attached its listener).
      vim.api.nvim_exec_autocmds('FileType', { buffer = 0 })
    end,
  },
}

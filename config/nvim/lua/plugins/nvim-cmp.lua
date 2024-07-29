return {
  {
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter' },
    dependencies = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'quangnguyen30192/cmp-nvim-ultisnips',
      'zbirenbaum/copilot-cmp',
    },
    config = function()
      local cmp = require('cmp')
      local map = cmp.mapping

      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn['UltiSnips#Anon'](args.body) -- For `ultisnips` users.
          end,
        },

        mapping = map.preset.insert({
          ['<C-b>'] = map.scroll_docs(-4),
          ['<C-f>'] = map.scroll_docs(4),
          ['<C-e>'] = map.abort(),
          ['<C-s>'] = map.confirm({ select = true }),
        }),

        sources = cmp.config.sources(
          {
            { name = 'nvim_lsp' },
            { name = 'ultisnips' },
            { name = 'path' },
          },

          -- if lsp is not available, use buffer
          {
            { name = 'buffer' },
          }
        ),
      })

      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
        },
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
        }, {
          { name = 'cmdline' },
        }),
      })
    end,
  },
}

return {
  {
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter' },
    config = function()
      local cmp = require('cmp')
      local map = cmp.mapping

      cmp.setup({
        snippet = {
          expand = function(args)
            if vim.fn.exists('*UltiSnips#Anon') == 1 then
              vim.fn['UltiSnips#Anon'](args.body) -- For `ultisnips` users.
            end
          end,
        },

        mapping = map.preset.insert({
          ['<C-b>'] = map.scroll_docs(-4),
          ['<C-f>'] = map.scroll_docs(4),
          ['<C-g>'] = map.abort(),
          -- Custom Tab mapping with copilot-lsp priority
          ['<Tab>'] = map(function(fallback)
            local bufnr = vim.api.nvim_get_current_buf()
            local copilot_state = vim.b[bufnr].nes_state

            -- Priority 1: Copilot-LSP suggestion
            if copilot_state then
              if require('copilot-lsp.nes').apply_pending_nes() then
                require('copilot-lsp.nes').walk_cursor_end_edit()
                return
              end
            end

            -- Priority 2: nvim-cmp completion
            if cmp.visible() then
              cmp.confirm({ select = true })
            else
              -- Priority 3: Default Tab behavior
              fallback()
            end
          end, { 'i', 's' }),

          ['<C-e>'] = map.complete(),
          ['<C-n>'] = map.select_next_item(),
          ['<C-p>'] = map.select_prev_item(),
        }),

        sources = cmp.config.sources(
          {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'path' },
            { name = 'git' },
          },

          -- if lsp is not available, use buffer
          {
            { name = 'buffer' },
          }
        ),

        experimental = {
          ghost_text = true,
        },

        sorting = {
          priority_weight = 2,
          comparators = {
            -- Below is the default comparitor list and order for nvim-cmp
            cmp.config.compare.offset,
            -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },

        formatting = {
          format = require('lspkind').cmp_format({
            mode = 'symbol',
            maxwidth = 50,
            ellipsis_char = '…',
            show_labelDetails = true,
            symbol_map = {
              Copilot = '',
            },
          }),
        },
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
    dependencies = {
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-cmdline' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/cmp-path' },
      {
        'petertriho/cmp-git',
        config = function()
          require('cmp_git').setup({
            github = {
              issues = {
                state = 'all',
              },
            },
          })
        end,
      },
      { 'onsails/lspkind.nvim' },
      { 'saadparwaiz1/cmp_luasnip' },
    },
  },
}

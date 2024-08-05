return {
  {
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter' },
    config = function()
      local cmp = require('cmp')
      local map = cmp.mapping

      -- Tab Completion Configuration (Highly Recommended)
      -- from: https://github.com/zbirenbaum/copilot-cmp#tab-completion-configuration-highly-recommended
      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
          return false
        end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match('^%s*$') == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn['UltiSnips#Anon'](args.body) -- For `ultisnips` users.
          end,
        },

        mapping = map.preset.insert({
          ['<C-b>'] = map.scroll_docs(-4),
          ['<C-f>'] = map.scroll_docs(4),
          ['<C-g>'] = map.abort(),
          ['<Tab>'] = map.confirm({ select = true }),
          ['<C-e>'] = map.complete(),
          ['<C-n>'] = map.select_next_item(),
          ['<C-p>'] = map.select_prev_item(),
        }),

        sources = cmp.config.sources(
          {
            { name = 'copilot' },
            { name = 'nvim_lsp' },
            { name = 'ultisnips' },
            { name = 'path' },
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
            require('copilot_cmp.comparators').prioritize,

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
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'quangnguyen30192/cmp-nvim-ultisnips',
      {
        'zbirenbaum/copilot-cmp',
        dependencies = {
          'zbirenbaum/copilot.lua',
        },
        config = function()
          require('copilot_cmp').setup({
            panel = { enabled = false },
          })
        end,
      },
    },
  },
}

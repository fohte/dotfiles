return {
  {
    'saghen/blink.cmp',
    event = { 'InsertEnter' },
    dependencies = {
      'onsails/lspkind.nvim',
      'fang2hou/blink-copilot',
      'L3MON4D3/LuaSnip',
      'xzbdmw/colorful-menu.nvim',
    },
    version = '1.*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        -- Custom Tab mapping with copilot-lsp NES priority
        ['<Tab>'] = {
          function(cmp)
            local bufnr = vim.api.nvim_get_current_buf()
            -- Handle Copilot NES (Next Edit Suggestion) first
            if vim.b[bufnr].nes_state then
              cmp.hide()
              return (
                require('copilot-lsp.nes').apply_pending_nes()
                and require('copilot-lsp.nes').walk_cursor_end_edit()
              )
            end
            -- Then handle normal completion
            if cmp.is_visible() then
              return cmp.accept()
            end
          end,
          'snippet_forward',
          'fallback',
        },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        documentation = {
          auto_show = true, -- Show documentation automatically
          auto_show_delay_ms = 200,
          window = {
            border = 'rounded',
          },
        },
        ghost_text = {
          enabled = true,
        },
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        menu = {
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
          draw = {
            columns = { { 'kind_icon' }, { 'label', gap = 1 }, { 'kind' } },
            treesitter = { 'lsp' },
            components = {
              kind = {
                highlight = function(ctx)
                  return 'BlinkCmpKind' .. ctx.kind
                end,
              },
            },
          },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'copilot', 'snippets', 'buffer' },
        providers = {
          lsp = {
            enabled = true,
          },
          path = {
            enabled = true,
          },
          snippets = {
            enabled = true,
          },
          buffer = {
            enabled = true,
          },
          copilot = {
            name = 'copilot',
            module = 'blink-copilot',
            score_offset = 100,
            async = true,
          },
        },
      },

      snippets = {
        preset = 'luasnip',
      },
    },
  },
}

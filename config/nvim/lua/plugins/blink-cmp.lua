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
        -- Manual trigger completion
        ['<C-e>'] = { 'show' },
        ['<C-u>'] = { 'cancel' },
        -- Custom Tab mapping: prioritize completion when menu is visible
        ['<Tab>'] = {
          function(cmp)
            -- First check if completion menu is visible
            if cmp.is_visible() then
              return cmp.accept()
            end

            -- Then handle Copilot NES
            local nes = require('copilot-lsp.nes')
            local bufnr = vim.api.nvim_get_current_buf()
            if vim.b[bufnr].nes_state then
              cmp.hide()
              return nes.apply_pending_nes() and nes.walk_cursor_end_edit()
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
        trigger = {
          show_on_keyword = true, -- Show after typing keywords
          show_on_trigger_character = true, -- Show after typing trigger characters (., :, etc.)
          show_on_backspace = false, -- Don't show after backspace
          show_on_backspace_in_keyword = true, -- Show after backspacing in a keyword
          show_on_backspace_after_accept = true, -- Show after accepting and backspacing
          show_in_snippet = true, -- Show in snippet
        },
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
            preselect = true,
            auto_insert = true,
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

      signature = {
        enabled = true,
        trigger = {
          enabled = true, -- Enable automatic signature help
          show_on_trigger_character = true, -- Show when typing (
          show_on_insert_on_trigger_character = true, -- Show when entering insert mode after (
        },
        window = {
          border = 'rounded',
        },
      },
    },
  },
}

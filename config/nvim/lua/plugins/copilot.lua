return {
  {
    'copilotlsp-nvim/copilot-lsp',
    event = 'InsertEnter',
    init = function()
      vim.g.copilot_nes_debounce = 100 -- Reduce debounce from 500ms to 100ms
      vim.lsp.enable('copilot_ls')
    end,
    config = function()
      require('copilot-lsp').setup({
        nes = {
          move_count_threshold = 2, -- Reduce from 3 to 2 for faster clearing
        },
      })

      vim.keymap.set('n', '<tab>', function()
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.b[bufnr].nes_state then
          -- Try to jump to the start of the suggestion edit.
          -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
          local nes = require('copilot-lsp.nes')
          local _ = nes.walk_cursor_start_edit() or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
          return nil
        else
          -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
          return '<C-i>'
        end
      end, { desc = 'Accept Copilot NES suggestion', expr = true })

      vim.keymap.set('n', '<esc>', function()
        if not require('copilot-lsp.nes').clear() then
          -- fallback to other functionality
          return '<esc>'
        end
      end, { desc = 'Clear Copilot suggestion or fallback', expr = true })
    end,
  },
}

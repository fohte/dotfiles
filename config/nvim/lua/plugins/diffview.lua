return {
  'sindrets/diffview.nvim',
  keys = {
    {
      '<leader>dr',
      '<cmd>DiffviewOpen origin/master...HEAD --imply-local<cr>',
      desc = 'Diffview: PR review (merge-base)',
    },
    {
      '<leader>do',
      '<cmd>DiffviewOpen<cr>',
      desc = 'Diffview: open',
    },
  },
  config = function()
    local diffview = require('diffview')

    diffview.setup({
      hooks = {
        -- base: https://github.com/sindrets/diffview.nvim/pull/258#issuecomment-1408689220
        diff_buf_win_enter = function(bufnr, winid, ctx)
          if ctx.layout_name:match('^diff2') then
            if ctx.symbol == 'a' then
              vim.opt_local.winhl = table.concat({
                'DiffAdd:DiffviewDiffAddAsDelete',
                'DiffDelete:DiffviewDiffDeleteDim',
                'DiffText:DiffviewDiffTextDelete',
                'DiffChange:DiffviewDiffDelete',
              }, ',')
            elseif ctx.symbol == 'b' then
              vim.opt_local.winhl = table.concat({
                'DiffDelete:DiffviewDiffDeleteDim',
                'DiffChange:DiffviewDiffAdd',
                'DiffText:DiffviewDiffTextAdd',
              }, ',')
            end
          end
        end,
      },
      keymaps = {
        view = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
        diff1 = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
        diff2 = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
        diff3 = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
        diff4 = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
        file_panel = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
        file_history_panel = {
          { 'n', 'q', diffview.close, { desc = 'Close the diffview' } },
        },
      },
    })
  end,
}

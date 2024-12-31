return {
  'sindrets/diffview.nvim',
  config = function()
    require('diffview').setup({
      -- base: https://github.com/sindrets/diffview.nvim/pull/258#issuecomment-1408689220
      hooks = {
        diff_buf_win_enter = function(bufnr, winid, ctx)
          if ctx.layout_name:match('^diff2') then
            if ctx.symbol == 'a' then
              vim.opt_local.winhl = table.concat({
                'DiffAdd:DiffviewDiffAddAsDelete',
                'DiffDelete:DiffviewDiffDelete',
                'DiffText:DiffviewDiffTextDelete',
                'DiffChange:DiffviewDiffDelete',
              }, ',')
            elseif ctx.symbol == 'b' then
              vim.opt_local.winhl = table.concat({
                'DiffDelete:DiffviewDiffDelete',
                'DiffChange:DiffviewDiffAdd',
                'DiffText:DiffviewDiffTextAdd',
              }, ',')
            end
          end
        end,
      },
    })
  end,
}

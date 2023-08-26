return {
  'subnut/nvim-ghost.nvim',
  init = function()
    vim.g.nvim_ghost_autostart = 0
  end,
  config = function()
    vim.api.nvim_create_augroup('nvim_ghost_user_autocommands', { clear = true })
    vim.api.nvim_create_autocmd('User', {
      pattern = { '*github.com' },
      group = 'nvim_ghost_user_autocommands',
      callback = function()
        vim.opt.filetype = 'markdown'
      end,
    })
  end,
}

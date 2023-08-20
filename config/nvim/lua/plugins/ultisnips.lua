return {
  'SirVer/ultisnips',
  config = function()
    vim.g.UltiSnipsUsePythonVersion = 3

    vim.g.UltiSnipsSnippetDirectories = { vim.fn.stdpath('config') .. '/ultisnips' }

    vim.g.UltiSnipsExpandTrigger = '<C-t>'
    vim.g.UltiSnipsJumpForwardTrigger = '<TAB>'
    vim.g.UltiSnipsJumpBackwardTrigger = '<S-TAB>'

    vim.g.UltiSnipsEditSplit = 'vertical'
  end,
}

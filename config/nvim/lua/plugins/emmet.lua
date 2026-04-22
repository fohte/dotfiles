return {
  'mattn/emmet-vim',
  ft = { 'html', 'css', 'scss', 'sass', 'less', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'svelte' },
  init = function()
    vim.g.user_emmet_leader_key = '<C-e>'
    vim.g.user_emmet_settings = {
      javascript = {
        extends = 'jsx',
      },
    }
  end,
}

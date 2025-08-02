return {
  'mattn/emmet-vim',
  commit = 'e98397144982d1e75b20d94d55a82de3ec8f648d', -- renovate: branch=master
  config = function()
    vim.g.user_emmet_leader_key = '<C-e>'
    vim.g.user_emmet_settings = {
      javascript = {
        extends = 'jsx',
      },
    }
  end,
}

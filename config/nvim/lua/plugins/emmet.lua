return {
  'mattn/emmet-vim',
  commit = '6c511a8d7d2863066f32e25543e2bb99d505172c', -- renovate: branch=master
  config = function()
    vim.g.user_emmet_leader_key = '<C-e>'
    vim.g.user_emmet_settings = {
      javascript = {
        extends = 'jsx',
      },
    }
  end,
}

return {
  {
    'zbirenbaum/copilot.lua',
    commit = '4958fb9390f624cb389be2772e3c5e718e94d8b6', -- renovate: branch=master
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        filetypes = {
          ['*'] = true,
        },
      })
    end,
  },
}

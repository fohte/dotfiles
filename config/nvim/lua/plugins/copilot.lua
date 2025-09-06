return {
  {
    'zbirenbaum/copilot.lua',
    commit = '81d289a8ce5d4ee1dea9b1c8ee4ac376b2e27a5f', -- renovate: branch=master
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

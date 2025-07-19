return {
  {
    'zbirenbaum/copilot.lua',
    commit = '14bf786180b2ca4578915c56989b6d676dddc6f3', -- renovate: branch=master
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

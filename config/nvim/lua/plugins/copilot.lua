return {
  {
    'zbirenbaum/copilot.lua',
    commit = '0f2fd3829dd27d682e46c244cf48d9715726f612', -- renovate: branch=master
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

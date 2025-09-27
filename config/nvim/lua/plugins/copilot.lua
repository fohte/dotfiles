return {
  {
    'zbirenbaum/copilot.lua',
    commit = '619493a538c140393f0c80fd386144e0b5d3b96f', -- renovate: branch=master
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

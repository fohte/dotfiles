return {
  {
    'zbirenbaum/copilot.lua',
    commit = 'f0c0d981de2737abc50bd7b5bb034ae440826827', -- renovate: branch=master
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

return {
  {
    'zbirenbaum/copilot.lua',
    commit = '8e52d47e4033fa0659c25deb39a39b61c86adb45', -- renovate: branch=master
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

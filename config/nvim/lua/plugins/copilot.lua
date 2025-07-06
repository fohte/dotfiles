return {
  {
    'zbirenbaum/copilot.lua',
    commit = '46f4b7d026cba9497159dcd3e6aa61a185cb1c48',
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

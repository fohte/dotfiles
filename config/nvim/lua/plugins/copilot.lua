return {
  {
    'zbirenbaum/copilot.lua',
    commit = 'ef3fc4af72942bf43749cea6fe6598e4da63d415', -- renovate: branch=master
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

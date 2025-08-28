return {
  {
    'zbirenbaum/copilot.lua',
    commit = '2fe9ab1678da4f40be4948a2f30cc8b58da7818a', -- renovate: branch=master
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

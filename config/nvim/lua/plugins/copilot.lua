return {
  {
    'zbirenbaum/copilot.lua',
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
  {
    {
      'CopilotC-Nvim/CopilotChat.nvim',
      branch = 'canary',
      dependencies = {
        { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
        { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
        { 'nvim-telescope/telescope.nvim' }, -- integrate with telescope
      },
      build = 'make tiktoken', -- Only on MacOS or Linux
      config = function()
        require('CopilotChat').setup({
          window = {
            layout = 'float',
            relative = 'editor',
          },
        })
      end,
      keys = {
        {
          '<Leader>ec',
          function()
            require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions())
          end,
        },
        {
          '<Leader>ca',
          function()
            local input = vim.fn.input('Copilot Chat: ')
            if input ~= '' then
              require('CopilotChat').ask(input, { selection = require('CopilotChat.select').buffer })
            end
          end,
          mode = { 'n', 'v' },
        },
      },
    },
  },
}

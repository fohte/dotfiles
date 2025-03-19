return {
  {
    'zbirenbaum/copilot.lua',
    -- renovate: datasource=github-releases depName=zbirenbaum/copilot.lua
    commit = '86537b286f18783f8b67bccd78a4ef4345679625',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        filetypes = {
          ['*'] = true,

          -- disable copilot on text files
          ['markdown'] = false,
          -- ['review'] = false,
        },
      })
    end,
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    -- renovate: datasource=github-releases depName=CopilotC-Nvim/CopilotChat.nvim
    branch = 'canary',
    commit = '43d033b68c8bede4cc87092c7db6bb3bbb2fe145',
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
  {
    'yetone/avante.nvim',
    -- renovate: datasource=github-releases depName=yetone/avante.nvim
    commit = '0705234991d03170a72582085dc508600a03a779',
    event = 'VeryLazy',
    lazy = false,
    opts = {
      provider = 'copilot',
    },
    build = 'make',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      --- The below dependencies are optional,
      'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
      'zbirenbaum/copilot.lua', -- for providers='copilot'
      {
        -- support for image pasting
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        -- enable only for avante
        opts = {
          file_types = { 'Avante' },
        },
        ft = { 'Avante' },
      },
    },
  },
}

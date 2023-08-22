return {
  'RRethy/nvim-base16',
  config = function()
    local utils = require('utils')

    vim.cmd.colorscheme('base16-material-darker')

    local function set_hl(names, colors)
      for _, name in ipairs(names) do
        vim.api.nvim_set_hl(0, name, colors)
      end
    end

    -- search result highlight is too bright, so make it less bright
    -- The search result highlight is too bright, so make it less bright
    set_hl({ 'IncSearch' }, { bg = '#444444', fg = 'none' })
    set_hl({ 'Search' }, { link = 'IncSearch' })

    -- make matching bracket more visible
    set_hl({ 'MatchParen' }, { link = 'Number' })

    -- make line number less visible
    set_hl({ 'LineNr' }, { fg = '#444444' })

    -- make vertical split line less visible
    set_hl({ 'VertSplit' }, { fg = '#444444' })

    -- make comment text brighter
    set_hl({ 'Comment', 'TSComment' }, { fg = '#777777' })

    -- make transparent background (use terminal bacgkground color)
    local transparent_targets = {
      'Normal',
      'NormalNC',
      'SignColumn',
    }
    for _, target in ipairs(transparent_targets) do
      local current = vim.api.nvim_get_hl(0, { name = target })
      vim.api.nvim_set_hl(0, target, utils.mergeTables(current, { bg = 'none' }))
    end
  end,
}

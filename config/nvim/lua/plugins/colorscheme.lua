-- from: https://github.com/RRethy/base16-nvim/blob/6ac181b5733518040a33017dde654059cd771b7c/lua/base16-colorscheme.lua#L11-L53
local HEX_DIGITS = {
  ['0'] = 0,
  ['1'] = 1,
  ['2'] = 2,
  ['3'] = 3,
  ['4'] = 4,
  ['5'] = 5,
  ['6'] = 6,
  ['7'] = 7,
  ['8'] = 8,
  ['9'] = 9,
  ['a'] = 10,
  ['b'] = 11,
  ['c'] = 12,
  ['d'] = 13,
  ['e'] = 14,
  ['f'] = 15,
  ['A'] = 10,
  ['B'] = 11,
  ['C'] = 12,
  ['D'] = 13,
  ['E'] = 14,
  ['F'] = 15,
}

local function hex_to_rgb(hex)
  return HEX_DIGITS[string.sub(hex, 1, 1)] * 16 + HEX_DIGITS[string.sub(hex, 2, 2)],
    HEX_DIGITS[string.sub(hex, 3, 3)] * 16 + HEX_DIGITS[string.sub(hex, 4, 4)],
    HEX_DIGITS[string.sub(hex, 5, 5)] * 16 + HEX_DIGITS[string.sub(hex, 6, 6)]
end

local function rgb_to_hex(r, g, b)
  return bit.tohex(bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b), 6)
end

local function darken(hex, pct)
  pct = 1 - pct
  local r, g, b = hex_to_rgb(string.sub(hex, 2))
  r = math.floor(r * pct)
  g = math.floor(g * pct)
  b = math.floor(b * pct)
  return string.format('#%s', rgb_to_hex(r, g, b))
end

return {
  'RRethy/nvim-base16',
  config = function()
    local utils = require('utils')

    vim.cmd.colorscheme('base16-material-darker')

    local colorscheme = require('base16-colorscheme')
    local colors = colorscheme.colors

    local function set_hl(names, definition)
      for _, name in ipairs(names) do
        vim.api.nvim_set_hl(0, name, definition)
      end
    end

    set_hl({ 'DiffAdd', 'DiffAdded' }, { bg = darken(colors.base0B, 0.8) }) -- green
    set_hl({ 'DiffDelete', 'DiffRemoved' }, { bg = darken(colors.base08, 0.8) }) -- red
    set_hl({ 'DiffviewDiffTextAdd' }, { bg = darken(colors.base0B, 0.7) })
    set_hl({ 'DiffviewDiffTextDelete' }, { bg = darken(colors.base08, 0.7) })

    set_hl({ 'DiffChange', 'DiffLine' }, {}) -- ignore

    -- search result highlight is too bright, so make it less bright
    -- The search result highlight is too bright, so make it less bright
    set_hl({ 'IncSearch' }, { bg = '#444444', fg = 'none' })
    set_hl({ 'Search' }, { link = 'IncSearch' })
    set_hl({ 'CurSearch' }, { link = 'IncSearch' })

    -- make matching bracket more visible
    set_hl({ 'MatchParen' }, { link = 'Number' })

    -- make line number less visible
    set_hl({ 'LineNr' }, { fg = '#444444' })

    -- make window split line less visible
    set_hl({ 'VertSplit' }, { fg = '#444444' })
    set_hl({ 'WinSeparator' }, { link = 'Vertsplit' })

    -- make comment text brighter
    set_hl({ 'Comment', 'TSComment' }, { fg = '#777777' })

    -- make selected text background brighter
    set_hl({ 'Visual' }, { link = 'IncSearch' })

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

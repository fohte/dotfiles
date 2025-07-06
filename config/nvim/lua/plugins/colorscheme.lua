local hex_to_rgb = function(hex)
  hex = hex:gsub('#', '')
  return tonumber('0x' .. hex:sub(1, 2)), tonumber('0x' .. hex:sub(3, 4)), tonumber('0x' .. hex:sub(5, 6))
end

local rgb_to_hex = function(r, g, b)
  local rgb = (r * 0x10000) + (g * 0x100) + b
  return string.format('%x', rgb)
end

local hex_to_rgb_pct = function(hex, pct)
  local r, g, b = hex_to_rgb(string.sub(hex, 2))
  r = math.floor(r * pct)
  g = math.floor(g * pct)
  b = math.floor(b * pct)
  return string.format('#%s', rgb_to_hex(r, g, b))
end

return {
  'RRethy/nvim-base16',
  commit = 'aa923daec4e778cd31ccfb0dcf083aff3c442159',
  config = function()
    local utils = require('utils')

    vim.cmd.colorscheme('base16-material-darker')

    local colorscheme = require('base16-colorscheme')
    local colors = colorscheme.colors

    -- TODO: move to colorscheme
    -- base16 scheme does not define any background color for floating windows,
    -- so we define it ourselves
    vim.api.nvim_set_hl(0, 'NormalFloat', { bg = colors.base01 })

    -- make the border of floating windows more visible
    vim.api.nvim_set_hl(0, 'FloatBorder', { bg = colors.base01, fg = colors.base03 })

    -- FIX: cmp-nvim highlight
    -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance
    -- to make the completion menu more visible
    vim.api.nvim_set_hl(0, 'CmpItemAbbrDeprecated', { fg = colors.base03, strikethrough = true })
    vim.api.nvim_set_hl(0, 'CmpItemAbbrMatch', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchFuzzy', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemMenu', { fg = colors.base0E })

    vim.api.nvim_set_hl(0, 'CmpItemKindField', { fg = colors.base08 })
    vim.api.nvim_set_hl(0, 'CmpItemKindProperty', { fg = colors.base08 })
    vim.api.nvim_set_hl(0, 'CmpItemKindEvent', { fg = colors.base08 })

    vim.api.nvim_set_hl(0, 'CmpItemKindText', { fg = colors.base0B })
    vim.api.nvim_set_hl(0, 'CmpItemKindEnum', { fg = colors.base0B })
    vim.api.nvim_set_hl(0, 'CmpItemKindKeyword', { fg = colors.base0B })

    vim.api.nvim_set_hl(0, 'CmpItemKindConstant', { fg = colors.base09 })
    vim.api.nvim_set_hl(0, 'CmpItemKindConstructor', { fg = colors.base09 })
    vim.api.nvim_set_hl(0, 'CmpItemKindReference', { fg = colors.base09 })

    vim.api.nvim_set_hl(0, 'CmpItemKindFunction', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemKindStruct', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemKindClass', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemKindModule', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemKindOperator', { fg = colors.base0D })

    vim.api.nvim_set_hl(0, 'CmpItemKindVariable', { fg = colors.base0E })
    vim.api.nvim_set_hl(0, 'CmpItemKindFile', { fg = colors.base0E })

    vim.api.nvim_set_hl(0, 'CmpItemKindUnit', { fg = colors.base0A })
    vim.api.nvim_set_hl(0, 'CmpItemKindSnippet', { fg = colors.base0A })
    vim.api.nvim_set_hl(0, 'CmpItemKindFolder', { fg = colors.base0A })

    vim.api.nvim_set_hl(0, 'CmpItemKindMethod', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemKindValue', { fg = colors.base0D })
    vim.api.nvim_set_hl(0, 'CmpItemKindEnumMember', { fg = colors.base0D })

    vim.api.nvim_set_hl(0, 'CmpItemKindInterface', { fg = colors.base0C })
    vim.api.nvim_set_hl(0, 'CmpItemKindColor', { fg = colors.base0C })
    vim.api.nvim_set_hl(0, 'CmpItemKindTypeParameter', { fg = colors.base0C })

    -- modes.nvim
    local function darken(hex, pct)
      local r, g, b = hex_to_rgb(hex)
      r = math.floor(r * pct)
      g = math.floor(g * pct)
      b = math.floor(b * pct)
      return string.format('#%s', rgb_to_hex(r, g, b))
    end

    vim.api.nvim_set_hl(0, 'ModesCopy', { bg = darken(colors.base0B, 0.2) })
    vim.api.nvim_set_hl(0, 'ModesDelete', { bg = darken(colors.base08, 0.2) })
    vim.api.nvim_set_hl(0, 'ModesInsert', { bg = darken(colors.base0D, 0.2) })
    vim.api.nvim_set_hl(0, 'ModesVisual', { bg = darken(colors.base0E, 0.2) })

    -- FIX: octo.nvim highlight
    -- https://github.com/pwntester/octo.nvim/issues/382
    vim.api.nvim_set_hl(0, 'OctoEditable', { bg = colors.base01 })

    -- Indent Blankline
    vim.api.nvim_set_hl(0, 'IndentBlanklineChar', { fg = hex_to_rgb_pct(colors.base05, 0.2) })
  end,
}

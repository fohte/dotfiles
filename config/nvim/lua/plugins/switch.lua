return {
  'AndrewRadev/switch.vim',
  init = function()
    vim.g.switch_mapping = '_'

    vim.g.switch_custom_definitions = {
      { ['\\v^( *- *)\\[x\\](.*)$'] = '\\1[ ]\\2' },
      { ['\\v^( *- *)\\[ \\](.*)$'] = '\\1[x]\\2' },
    }
  end,
}

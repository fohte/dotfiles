return {
  'AndrewRadev/switch.vim',
  commit = 'df58397cfa36d2f428ddc2652ba32d1db2af6d02',
  init = function()
    vim.g.switch_mapping = '_'

    vim.g.switch_custom_definitions = {
      { ['\\v^( *- *)\\[x\\](.*)$'] = '\\1[ ]\\2' },
      { ['\\v^( *- *)\\[ \\](.*)$'] = '\\1[x]\\2' },
    }
  end,
}

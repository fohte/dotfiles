return {
  'AndrewRadev/switch.vim',
  commit = '4017a58f7ed8a2d76a288e36130affe8eb55e83a', -- renovate: branch=main
  init = function()
    vim.g.switch_mapping = '_'

    vim.g.switch_custom_definitions = {
      { ['\\v^( *- *)\\[x\\](.*)$'] = '\\1[ ]\\2' },
      { ['\\v^( *- *)\\[ \\](.*)$'] = '\\1[x]\\2' },
    }
  end,
}

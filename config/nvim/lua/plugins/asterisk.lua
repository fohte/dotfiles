return {
  'haya14busa/vim-asterisk',
  -- renovate: datasource=github-releases depName=haya14busa/vim-asterisk
  commit = '77e97061d6691637a034258cc415d98670698459',
  config = function()
    vim.g['asterisk#keeppos'] = 1
  end,
  keys = {
    { '*', '<Plug>(asterisk-z*)', mode = { 'n', 'v', 'o' } },
    { '#', '<Plug>(asterisk-z#)', mode = { 'n', 'v', 'o' } },
    { 'g*', '<Plug>(asterisk-gz*)', mode = { 'n', 'v', 'o' } },
    { 'g*', '<Plug>(asterisk-gz#)', mode = { 'n', 'v', 'o' } },
  },
}

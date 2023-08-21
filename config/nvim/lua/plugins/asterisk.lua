return {
  'haya14busa/vim-asterisk',
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

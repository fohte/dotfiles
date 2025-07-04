return {
  'haya14busa/vim-asterisk',
  version = 'v1.0.0',
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

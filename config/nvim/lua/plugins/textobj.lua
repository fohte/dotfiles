return {
  'kana/vim-textobj-user',
  version = '0.7.6',
  {
    'rhysd/vim-textobj-ruby',
    dependencies = { 'kana/vim-textobj-user' },
    ft = 'ruby',
  },
  {
    'kana/vim-textobj-indent',
    version = '0.0.6',
    dependencies = { 'kana/vim-textobj-user' },
  },
  {
    'glts/vim-textobj-comment',
    version = 'v1.0.0',
    dependencies = { 'kana/vim-textobj-user' },
    keys = {
      { 'i-', '<Plug>(textobj-comment-i)', mode = { 'o', 'x' } },
      { 'a-', '<Plug>(textobj-comment-a)', mode = { 'o', 'x' } },
    },
  },
  {
    'osyo-manga/vim-textobj-multiblock',
    dependencies = { 'kana/vim-textobj-user' },
    keys = {
      { 'ib', '<Plug>(textobj-multiblock-i)', mode = { 'o', 'x' } },
      { 'ab', '<Plug>(textobj-multiblock-a)', mode = { 'o', 'x' } },
    },
  },
  {
    'osyo-manga/vim-textobj-blockwise',
    dependencies = { 'kana/vim-textobj-user' },
  },
  {
    'sgur/vim-textobj-parameter',
    dependencies = { 'kana/vim-textobj-user' },
  },
  {
    'thinca/vim-textobj-between',
    version = 'v0.1.0',
    dependencies = { 'kana/vim-textobj-user' },
    init = function()
      vim.g.textobj_between_no_default_key_mappings = 1
    end,
    keys = {
      { 'if', '<Plug>(textobj-between-i)', mode = { 'o', 'x' } },
      { 'af', '<Plug>(textobj-between-a)', mode = { 'o', 'x' } },
    },
  },
  {
    'kana/vim-textobj-syntax',
    version = '0.0.2',
    dependencies = { 'kana/vim-textobj-user' },
    init = function()
      vim.g.textobj_syntax_no_default_key_mappings = 1
    end,
    keys = {
      { 'ic', '<Plug>(textobj-syntax-i)', mode = { 'o', 'x' } },
      { 'ac', '<Plug>(textobj-syntax-a)', mode = { 'o', 'x' } },
    },
  },
}

return {
  { 'kana/vim-textobj-user', commit = '41a675ddbeefd6a93664a4dc52f302fe3086a933' },
  {
    'rhysd/vim-textobj-ruby',
    commit = 'fb99d918273a65010b3ac4084371a19c34260c66',
    dependencies = { 'kana/vim-textobj-user' },
    ft = 'ruby',
  },
  {
    'kana/vim-textobj-indent',
    commit = 'deb76867c302f933c8f21753806cbf2d8461b548',
    dependencies = { 'kana/vim-textobj-user' },
  },
  {
    'glts/vim-textobj-comment',
    commit = '58ae4571b76a5bf74850698f23d235eef991dd4b',
    dependencies = { 'kana/vim-textobj-user' },
    keys = {
      { 'i-', '<Plug>(textobj-comment-i)', mode = { 'o', 'x' } },
      { 'a-', '<Plug>(textobj-comment-a)', mode = { 'o', 'x' } },
    },
  },
  {
    'osyo-manga/vim-textobj-multiblock',
    commit = '670a5ba57d73fcd793f480e262617c6eb0103355',
    dependencies = { 'kana/vim-textobj-user' },
    keys = {
      { 'ib', '<Plug>(textobj-multiblock-i)', mode = { 'o', 'x' } },
      { 'ab', '<Plug>(textobj-multiblock-a)', mode = { 'o', 'x' } },
    },
  },
  {
    'osyo-manga/vim-textobj-blockwise',
    commit = 'c731da12fbd5728a22fb8d3c800b8bcdcbf94da8',
    dependencies = { 'kana/vim-textobj-user' },
  },
  {
    'sgur/vim-textobj-parameter',
    commit = '201144f19a1a7081033b3cf2b088916dd0bcb98c',
    dependencies = { 'kana/vim-textobj-user' },
  },
  {
    'thinca/vim-textobj-between',
    commit = 'fa7723c08b1f2d55e1a30ba720d2fd4db27cb1e8',
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
    commit = 'a0167c2680f8a35d9ca1f47ddf31070492893175',
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

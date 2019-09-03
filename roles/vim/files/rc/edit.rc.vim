if has('clipboard')
  set clipboard&
  if has('unnamedplus')
    set clipboard^=unnamedplus
  else
    set clipboard^=unnamed
  endif
endif

if !exists('loaded_matchit')
  runtime macros/matchit.vim
endif

set mouse=a

set foldmethod=manual

set autoread

set noswapfile
set nobackup
set undofile

set smartindent
set expandtab
set tabstop=2
set shiftwidth=2
set shiftround

set backspace=indent,eol,start

set hlsearch
set incsearch
set ignorecase
set smartcase
set wrapscan

set showcmd
set switchbuf=useopen,vsplit

if has('nvim')
  set inccommand=split
endif

set sessionoptions=blank,curdir,folds,tabpages,winsize

set sh=bash

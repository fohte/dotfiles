" ----------------------------------------------------------
"                .__
"          ___  _|__| ____________   ____
"          \  \/ /  |/     \_  __ \_/ ___\
"           \   /|  |  Y Y  \  | \/\  \___
"            \_/ |__|__|_|  /__|    \___  >
"                         \/            \/    @Fohte
" ----------------------------------------------------------

if has('vim_starting') && &encoding !=# 'utf-8'
   set encoding=utf-8
endif
set imd

filetype plugin indent on

" disable python2
let g:python_host_prog = ''

if executable('pyenv')
  let g:python3_host_prog = expand('~/.pyenv/shims/python3')
endif

let $CACHE = expand('~/.cache')
if !isdirectory($CACHE)
  call mkdir($CACHE, 'p')
endif

let g:mapleader = "\<Space>"

call util#source_rc('setup_dein.rc.vim')

lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "javascript",
    "lua",
    "tsx",
    "typescript",
    "vim",
  },
  highlight = {
    enable = true,
    disable = {},
  },
}
EOF

call util#source_rc('edit.rc.vim')
call util#source_rc('view.rc.vim')
call util#source_rc('mappings.rc.vim')
call util#source_rc('commands.rc.vim')
call util#source_rc('quickfix.rc.vim')

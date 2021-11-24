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

let g:nvim_rc_dir = resolve(expand('~/.config/nvim/rc'))

function! s:source_rc(path) abort
  let l:abspath = resolve(expand(g:nvim_rc_dir . '/' . a:path))
  execute 'source' fnameescape(l:abspath)
endfunction

call s:source_rc('utils.rc.vim')

let g:mapleader = "\<Space>"

call s:source_rc('setup_dein.rc.vim')

lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true,
    disable = {},
  },
}
EOF

call s:source_rc('edit.rc.vim')
call s:source_rc('view.rc.vim')
call s:source_rc('mappings.rc.vim')
call s:source_rc('commands.rc.vim')
call s:source_rc('quickfix.rc.vim')

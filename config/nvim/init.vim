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

let s:rc_dir = resolve(expand('~/.config/nvim/rc'))

function! s:source_rc(path) abort
  let l:abspath = resolve(expand(s:rc_dir . '/' . a:path))
  execute 'source' fnameescape(l:abspath)
endfunction

call s:source_rc('utils.rc.vim')

let g:mapleader = "\<Space>"

let s:dein_dir = expand($CACHE . '/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

let s:toml_dir = expand(s:rc_dir . '/plugins')

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir, [expand('<sfile>')] + split(glob(s:toml_dir . '/*.toml'), '\n'))

  call dein#load_toml(s:toml_dir . '/dein.toml', {'lazy': 0})
  call dein#load_toml(s:toml_dir . '/dein.lazy.toml', {'lazy': 1})
  call dein#load_toml(s:toml_dir . '/dein.syntax.toml', {'lazy': 1})
  call dein#load_toml(s:toml_dir . '/dein.textobj.toml', {'lazy': 0})
  call dein#load_toml(s:toml_dir . '/dein.operator.toml', {'lazy': 0})

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

if has('vim_starting')
  call dein#call_hook('source')
endif

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

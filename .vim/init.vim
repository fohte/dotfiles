" ----------------------------------------------------------
"                .__
"          ___  _|__| ____________   ____
"          \  \/ /  |/     \_  __ \_/ ___\
"           \   /|  |  Y Y  \  | \/\  \___
"            \_/ |__|__|_|  /__|    \___  >
"                         \/            \/    @Fohte
" ----------------------------------------------------------

let $CACHE = expand('~/.cache')
if !isdirectory($CACHE)
  call mkdir($CACHE, 'p')
endif

let s:rc_dir = resolve(expand('~/.vim/rc'))

function! s:source_rc(path) abort
  let abspath = resolve(expand(s:rc_dir . '/' . a:path))
  execute 'source' fnameescape(abspath)
endfunction

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
  call dein#begin(s:dein_dir, [expand('<sfile>')] + split(glob(s:rc_dir . '/*.toml'), '\n'))

  call dein#load_toml(s:toml_dir . '/dein.toml', {'lazy': 0})
  call dein#load_toml(s:toml_dir . '/dein.lazy.toml', {'lazy': 1})
  call dein#load_toml(s:toml_dir . '/dein.syntax.toml', {'lazy': 1})
  call dein#load_toml(s:toml_dir . '/dein.textobj.toml', {'lazy': 0})
  call dein#load_toml(s:toml_dir . '/dein.operator.toml', {'lazy': 0})

  call dein#end()
  call dein#save_state()
endif

if has('vim_starting')
  call dein#call_hook('source')
endif

filetype plugin indent on

call s:source_rc('edit.rc.vim')

call s:source_rc('view.rc.vim')

call s:source_rc('mappings.rc.vim')

call s:source_rc('utils.rc.vim')

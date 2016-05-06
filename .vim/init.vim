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


" ----------------------------------------------------------
"   Plugins
" ----------------------------------------------------------
let s:dein_dir = expand($CACHE . '/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif


call dein#begin(s:dein_dir)

let s:toml      = '~/.vim/rc/dein.toml'
let s:toml_lazy = '~/.vim/rc/dein.lazy.toml'

if dein#load_cache([expand('<sfile>'), s:toml, s:toml_lazy])
  call dein#load_toml(s:toml,      {'lazy': 0})
  call dein#load_toml(s:toml_lazy, {'lazy': 1})
  call dein#save_cache()
endif

call s:source_rc('plugins.rc.vim')

call dein#end()



" ----------------------------------------------------------
"   Editor Settings
" ----------------------------------------------------------
filetype plugin indent on
call s:source_rc('edit.rc.vim')

" ----------------------------------------------------------
"   View
" ----------------------------------------------------------
call s:source_rc('view.rc.vim')

" ----------------------------------------------------------
"   Key Mappings
" ----------------------------------------------------------
call s:source_rc('mappings.rc.vim')

" ----------------------------------------------------------
"   Utils
" ----------------------------------------------------------
call s:source_rc('utils.rc.vim')


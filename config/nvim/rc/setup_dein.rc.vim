let g:dein#install_github_api_token = $GITHUB_TOKEN

let s:dein_dir = expand($CACHE . '/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

let s:toml_dir = expand(g:util#nvim_rc_dir . '/plugins')

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

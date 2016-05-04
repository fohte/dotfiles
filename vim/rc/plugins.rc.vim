if has('nvim') && dein#tap('deoplete.nvim')
  let g:deoplete#enable_at_startup = 1
  let g:deoplete#enable_ignore_case = 1
  let g:deoplete#enable_smart_case = 1
  let g:deoplete#enable_camel_case = 0
  let g:deoplete#max_list = 10
  let g:deoplete#enable_refresh_always = 0
  let g:deoplete#auto_complete_start_length = 2

  let g:deoplete#keyword_patterns = {}
  let g:deoplete#keyword_patterns._ = '[a-zA-Z_]\k*\(?'

  let g:deoplete#omni#input_patterns = {}
  let g:deoplete#omni#input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'

  inoremap <expr> <TAB>   pumvisible() ? "\<C-n>" : "\<TAB>"
  inoremap <expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
  inoremap <expr> <BS>    deoplete#mappings#close_popup()."\<C-h>"
endif

if has('lua') && dein#tap('neocomplete.vim')
endif

if dein#tap('unite.vim')
  call unite#custom#profile('default', 'context', {
    \ 'prompt': '> ',
    \ 'prompt_focus': 1,
    \ 'prompt_direction': 'top',
    \ 'split' : 0,
  \ })

  call unite#custom#source('buffer', 'sorters', 'sorter_word')

  nnoremap [unite] <Nop>
  nmap <Space> [unite]
  map <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files -start-insert file file/new<CR>
  map <silent> [unite]p :<C-u>call <SID>unite_file_rec()<CR>
  map <silent> [unite]b :<C-u>Unite buffer -auto-preview<CR>

  autocmd FileType unite call s:unite_settings()
endif

function! s:unite_file_rec()
  if isdirectory(getcwd().'/.git')
    execute 'Unite -start-insert file_rec/git:--others:--cached:--exclude-standard'
  else
    execute 'Unite -start-insert file_rec/async'
  endif
endfunction

function! s:unite_settings()
  nnoremap <silent><buffer><expr> <C-s> unite#do_action('split')
  inoremap <silent><buffer><expr> <C-s> unite#do_action('split')
  nnoremap <silent><buffer><expr> <C-v> unite#do_action('vsplit')
  inoremap <silent><buffer><expr> <C-v> unite#do_action('vsplit')
  nnoremap <silent><buffer><expr> <C-t> unite#do_action('tabopen')
  inoremap <silent><buffer><expr> <C-t> unite#do_action('tabopen')
endfunction

if dein#tap('vim-easymotion')
  let g:EasyMotion_keys='hjklasdfgyuiopqwertnmzxcvbHJKLASDFGYUIOPQWERTNMZXCVB'
  let g:EasyMotion_leader_key="'"
  nmap g/ <Plug>(easymotion-sn)
  xmap g/ <Plug>(easymotion-sn)
  omap g/ <Plug>(easymotion-tn)
endif

if dein#tap('lexima.vim')
  let g:lexima_enable_basic_rules = 0
endif

if dein#tap('lightline.vim')
  let g:lightline = {
  \   'colorscheme': 'landscape',
  \   'active': {
  \     'right': [['lineinfo'], ['filetype'], ['fileencoding', 'fileformat']]
  \   },
  \   'inactive': {
  \     'right': [['lineinfo'], ['filetype']]
  \   },
  \   'component': {
  \     'readonly': '%{&readonly ? "×" : ""}',
  \   },
  \   'separator': { 'left': '⮀', 'right': '⮂' },
  \   'subseparator': { 'left': '⮁', 'right': '⮃' },
  \ }
endif

if dein#tap('vim-over')
  nnoremap [over] <Nop>
  nmap , [over]
  nnoremap [over]s :OverCommandLine<CR>%s/\v
  nnoremap [over]w :OverCommandLine<CR>%s/<C-r><C-w>//g<Left><Left>
endif

if dein#tap('vim-submode')
  call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
  call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
  call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>-')
  call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>+')
  call submode#map('winsize', 'n', '', '>', '<C-w>>')
  call submode#map('winsize', 'n', '', '<', '<C-w><')
  call submode#map('winsize', 'n', '', '+', '<C-w>-')
  call submode#map('winsize', 'n', '', '-', '<C-w>+')
endif

if dein#tap('vim-pandoc-syntax')
  augroup pandoc_syntax
    au! BufNewFile,BufFilePRe,BufRead *.md set filetype=markdown.pandoc
  augroup END

  let g:pandoc#syntax#conceal#use = 0
endif

if dein#tap('deoplete-jedi')
  autocmd FileType python setlocal completeopt-=preview
endif

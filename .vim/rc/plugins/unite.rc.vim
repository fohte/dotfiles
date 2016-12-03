let g:unite_force_overwrite_statusline = 0

call unite#custom#profile('default', 'context', {
  \ 'prompt_direction': 'top',
  \ 'direction': 'botright',
  \ 'resume': 0,
\ })

call unite#custom#source('buffer', 'sorters', 'sorter_word')

nnoremap [unite] <Nop>
nmap <Space> [unite]
map <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files -start-insert file file/new<CR>
map <silent> [unite]p :<C-u>call  <SID>unite_file_rec()<CR>
map <silent> [unite]b :<C-u>Unite -buffer-name=buffers buffer<CR>
map <silent> [unite]o :<C-u>Unite -buffer-name=outlines -vertical -no-quit -resume -winwidth=40 outline<CR>
map <silent> [unite]g :<C-u>Unite grep:.<CR>

if executable('ag')
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts = '--ignore-case --nogroup --nocolor --hidden --ignore .git'
  let g:unite_source_grep_recursive_opt = ''
endif

autocmd FileType unite call s:unite_settings()

function! s:unite_file_rec()
  if isdirectory(getcwd().'/.git')
    execute 'Unite -buffer-name=files -start-insert file_rec/git:--others:--cached:--exclude-standard'
  else
    execute 'Unite -buffer-name=files -start-insert file_rec/async'
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

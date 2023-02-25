let g:coc_global_extensions = [
      \ 'coc-css',
      \ 'coc-fzf-preview',
      \ 'coc-json',
      \ 'coc-prettier',
      \ 'coc-prisma',
      \ 'coc-python',
      \ 'coc-solargraph',
      \ 'coc-tsserver',
      \ ]

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> <F9> <Plug>(coc-rename)

nnoremap <silent> K :call <SID>show_documentation()<CR>

nnoremap <silent> <F10> :Format<CR>
inoremap <silent> <F10> <C-o>:Format<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

call util#source_plugin_config('fzf-preview.rc.vim')

let g:coc_global_extensions = [
      \ 'coc-css',
      \ 'coc-fzf-preview',
      \ 'coc-json',
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

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

call util#source_rc('plugins/configs/fzf-preview.rc.vim')

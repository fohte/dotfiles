" let g:lsp_async_completion = 0
" let g:lsp_preview_keep_focus = 1
"
" function! s:find_root_uri(filename) abort
"   let l:buffer_filename = lsp#utils#find_nearest_parent_file_directory(
"  \   lsp#utils#get_buffer_path(),
"  \   a:filename,
"  \ )
"
"   return lsp#utils#path_to_uri(l:buffer_filename)
" endfunction
"
" if executable('flow-language-server')
"   autocmd User lsp_setup call lsp#register_server({
"  \   'name': 'flow-language-server',
"  \   'cmd': { server_info ->
"  \     [&shell, &shellcmdflag, 'flow-language-server --stdio --try-flow-bin']
"  \   },
"  \   'root_uri': { server_info -> s:find_root_uri('.flowconfig') },
"  \   'whitelist': ['javascript'],
"  \ })
" endif
"
" if executable('pyls')
"   autocmd User lsp_setup call lsp#register_server({
"  \   'name': 'pyls',
"  \   'cmd': { server_info -> ['pyls'] },
"  \   'whitelist': ['python'],
"  \ })
" endif
"
" if executable('solargraph')
"   autocmd User lsp_setup call lsp#register_server({
"  \   'name': 'solargraph',
"  \   'cmd': { server_info -> ['solargraph', 'stdio'] },
"  \   'whitelist': ['ruby'],
"  \ })
" endif
"
" if executable('typescript-language-server')
"   autocmd User lsp_setup call lsp#register_server({
"  \   'name': 'typescript-language-server',
"  \   'cmd': { server_info ->
"  \     [&shell, &shellcmdflag, 'typescript-language-server --stdio']
"  \   },
"  \   'root_uri': { server_info -> s:find_root_uri('tsconfig.json') },
"  \   'whitelist': ['typescript', 'typescript.tsx'],
"  \ })
" endif
"
" if executable('docker-langserver')
"   autocmd User lsp_setup call lsp#register_server({
"  \   'name': 'docker-langserver',
"  \   'cmd': { server_info ->
"  \     [&shell, &shellcmdflag, 'docker-langserver --stdio']
"  \   },
"  \   'whitelist': ['dockerfile'],
"  \ })
" endif
"
" if executable('rls')
"   autocmd User lsp_setup call lsp#register_server({
"  \   'name': 'rls',
"  \   'cmd': { server_info -> ['rustup', 'run', 'stable', 'rls'] },
"  \   'whitelist': ['rust'],
"  \ })
" endif
"
" nnoremap <silent> K :<C-u>LspHover<CR>
" nnoremap <silent> gd :<C-u>LspDefinition<CR>
" nnoremap <silent> <F2> :<C-u>LspRename<CR>

let g:coc_global_extensions = [
      \ 'coc-css',
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

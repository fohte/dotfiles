let g:lsp_async_completion = 0
let g:lsp_preview_keep_focus = 1

function! s:find_root_uri(filename) abort
  let l:buffer_filename = lsp#utils#find_nearest_parent_file_directory(
  \   lsp#utils#get_buffer_path(),
  \   a:filename,
  \ )

  return lsp#utils#path_to_uri(l:buffer_filename)
endfunction

if executable('flow-language-server')
  autocmd User lsp_setup call lsp#register_server({
  \   'name': 'flow-language-server',
  \   'cmd': { server_info ->
  \     [&shell, &shellcmdflag, 'flow-language-server --stdio --try-flow-bin']
  \   },
  \   'root_uri': { server_info -> s:find_root_uri('.flowconfig') },
  \   'whitelist': ['javascript'],
  \ })
endif

if executable('language_server-ruby')
  autocmd User lsp_setup call lsp#register_server({
  \   'name': 'language_server-ruby',
  \   'cmd': { server_info ->
  \     [&shell, &shellcmdflag, 'language_server-ruby']
  \   },
  \   'whitelist': ['ruby'],
  \ })
endif

if executable('typescript-language-server')
  autocmd User lsp_setup call lsp#register_server({
  \   'name': 'typescript-language-server',
  \   'cmd': { server_info ->
  \     [&shell, &shellcmdflag, 'typescript-language-server --stdio']
  \   },
  \   'root_uri': { server_info -> s:find_root_uri('tsconfig.json') },
  \   'whitelist': ['typescript'],
  \ })
endif

if executable('docker-langserver')
  autocmd User lsp_setup call lsp#register_server({
  \   'name': 'docker-langserver',
  \   'cmd': { server_info ->
  \     [&shell, &shellcmdflag, 'docker-langserver --stdio']
  \   },
  \   'whitelist': ['dockerfile'],
  \ })
endif

if executable('rls')
  autocmd User lsp_setup call lsp#register_server({
  \   'name': 'rls',
  \   'cmd': { server_info -> ['rustup', 'run', 'stable', 'rls'] },
  \   'whitelist': ['rust'],
  \ })
endif

nnoremap <silent> <CR> :<C-u>LspHover<CR>
nnoremap <silent> <C-p> :<C-u>pclose!<CR>

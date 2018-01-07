let g:lsp_async_completion = 0

if executable('flow-language-server')
  autocmd User lsp_setup call lsp#register_server({
  \   'name': 'flow-language-server',
  \   'cmd': { server_info ->
  \     [&shell, &shellcmdflag, 'flow-language-server --stdin']
  \   },
  \   'root_uri': { server_info ->
  \     lsp#utils#path_to_uri(
  \       lsp#utils#find_nearest_parent_file_directory(
  \         lsp#utils#get_buffer_path(), '.flowconfig'
  \       )
  \     )
  \   },
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

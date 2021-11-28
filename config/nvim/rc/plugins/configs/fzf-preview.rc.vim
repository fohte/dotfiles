function! s:run_fzf_grep()
  let l:input_value = input('Pattern: ')
  if l:input_value == ''
    return
  endif
  execute 'CocCommand fzf-preview.ProjectGrep' l:input_value
endfunction

function! s:run_fzf_files_in_current_dir()
  execute 'CocCommand fzf-preview.DirectoryFiles' expand('%:h')
endfunction

nmap <Leader>e [fzf-p]
xmap <Leader>e [fzf-p]

nnoremap <silent> [fzf-p]p     :<C-u>CocCommand fzf-preview.DirectoryFiles<CR>
nnoremap <silent> [fzf-p].     :<C-u>call <SID>run_fzf_files_in_current_dir()<CR>
nnoremap <silent> [fzf-p]s     :<C-u>CocCommand fzf-preview.GitStatus<CR>
nnoremap <silent> [fzf-p]<C-g> :<C-u>CocCommand fzf-preview.GitActions<CR>
nnoremap <silent> [fzf-p]b     :<C-u>CocCommand fzf-preview.Buffers<CR>
nnoremap <silent> [fzf-p]B     :<C-u>CocCommand fzf-preview.AllBuffers<CR>
nnoremap <silent> [fzf-p]o     :<C-u>CocCommand fzf-preview.FromResources buffer project_mru<CR>
nnoremap <silent> [fzf-p]/     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'"<CR>
nnoremap <silent> [fzf-p]*     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'<C-r>=expand('<cword>')<CR>"<CR>
nnoremap          [fzf-p]g     :<C-u>call <SID>run_fzf_grep()<CR>
xnoremap          [fzf-p]g     "sy:CocCommand   fzf-preview.ProjectGrep<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"

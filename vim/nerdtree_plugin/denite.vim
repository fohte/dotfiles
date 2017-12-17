nnoremap <Leader>nt :NERDTreeToggle<CR>
nnoremap <Leader>nf :NERDTreeFind<CR>

let g:NERDTreeShowHidden = 1

call g:NERDTreeAddKeyMap({ 'key': '<Leader>.', 'callback': 'NERDTreeDeniteFileRec' })
call g:NERDTreeAddKeyMap({ 'key': '<Leader>g', 'callback': 'NERDTreeDeniteGrep' })

function! g:NERDTreeDeniteFileRec() abort
  call s:execute_denite_with_selected_path('file_rec/git', [])
endfunction

function! g:NERDTreeDeniteGrep() abort
  call s:execute_denite_with_selected_path('grep', ['-no-empty'])
endfunction

function s:execute_denite_with_selected_path(command, options) abort
  execute 'Denite' a:command '-path=' . g:NERDTreeFileNode.GetSelected().path.str() join(a:options)
endfunction

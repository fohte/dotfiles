function! s:remove_dup_lines()
  if line('$') <= 1
    return
  endif

  let l:cursor_pos = getpos('.')

  while getline(1) ==# ''
    1delete_
  endwhile

  while getline('$') ==# ''
    $delete_
  endwhile

  call setpos('.', l:cursor_pos)
endfunction

command! RemoveDupLines call <SID>remove_dup_lines()

augroup MyAutoCmd
  autocmd!

  autocmd BufWritePre * RemoveDupLines

  autocmd VimResized * wincmd =
augroup END

command! VimShowHlGroup echo synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')

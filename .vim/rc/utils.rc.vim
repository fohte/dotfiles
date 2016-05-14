function! s:replace_chars()
  if &filetype ==# 'diff'
    return
  endif

  let cursor = getpos('.')

  " Remove spaces at the end of each line
  %s/\s\+$//ge

  " Remove last empty lines
  while line('$') > 1 && getline('$') == ''
    $delete _
  endwhile

  call setpos('.', cursor)
endfunction
autocmd MyAutoCmd BufWritePre * call s:replace_chars()

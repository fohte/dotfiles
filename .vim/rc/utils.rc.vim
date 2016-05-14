function! s:replace_chars()
  let cursor = getpos('.')

  " Remove spaces at the end of each line
  %s/\s\+$//ge

  " Remove last empty lines
  while getline('$') == ''
    $delete _
  endwhile

  call setpos('.', cursor)
endfunction
autocmd BufWritePre * call s:replace_chars()

function! s:replace_chars()
  if &filetype ==# 'diff'
    return
  endif

  let cursor = getpos('.')

  " Remove spaces at the end of each line
  if &filetype =~ 'markdown'
    " replace 3 or more spaces to 2 spaces
    %s/\v\s{3,}$/  /ge

    " remove only 1 spaces
    %s/\v([^ +] $)//ge

  else
    %s/\s\+$//ge

  endif

  " Remove first empty lines
  while line('$') > 1 && getline(1) == ''
    1delete _
  endwhile

  " Remove last empty lines
  while line('$') > 1 && getline('$') == ''
    $delete _
  endwhile

  call setpos('.', cursor)
endfunction
autocmd MyAutoCmd BufWritePre * call s:replace_chars()

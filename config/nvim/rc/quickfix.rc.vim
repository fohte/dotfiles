" default mode is localtion list
let s:quickfix_mode = 'l'

function! s:quickfix_mode()
  call s:close()

  let s:quickfix_mode = 'c'
  echo 'current mode: quickfix'
endfunction

function! s:loclist_mode()
  call s:close()

  let s:quickfix_mode = 'l'
  echo 'current mode: location list'
endfunction

function! s:toggle_mode()
  if s:quickfix_mode ==# 'l'
    call s:quickfix_mode()
  else
    call s:loclist_mode()
  endif
endfunction

function! s:execute(command)
  execute s:quickfix_mode . a:command
endfunction

function! s:next()
  call s:execute('next')
endfunction

function! s:previous()
  call s:execute('previous')
endfunction

function! s:last()
  call s:execute('last')
endfunction

function! s:first()
  call s:execute('first')
endfunction

function! s:current()
  call s:execute('c')
endfunction

function! s:open()
  let l:current_window_id = win_getid()
  call s:execute('open')
  call win_gotoid(l:current_window_id)
endfunction

function! s:close()
  call s:execute('close')
endfunction

" assign `q` to the prefix of quickfix commands
nnoremap q <Nop>
nnoremap <silent> qt :<C-u>call <SID>toggle_mode()<CR>
nnoremap <silent> qj :<C-u>call <SID>next()<CR>
nnoremap <silent> qk :<C-u>call <SID>previous()<CR>
nnoremap <silent> qJ :<C-u>call <SID>last()<CR>
nnoremap <silent> qK :<C-u>call <SID>first()<CR>
nnoremap <silent> qq :<C-u>call <SID>current()<CR>
nnoremap <silent> qo :<C-u>call <SID>open()<CR>
nnoremap <silent> qc :<C-u>call <SID>close()<CR>

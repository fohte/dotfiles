if g:float_window_available
  " https://github.com/junegunn/fzf.vim/issues/664#issuecomment-476438294
  let $FZF_DEFAULT_OPTS = $FZF_DEFAULT_OPTS . ' --layout=reverse'
  let g:fzf_layout = { 'window': 'call g:FloatingFZF()' }

  function! g:FloatingFZF()
    let buf = nvim_create_buf(v:false, v:true)
    " call setbufvar(buf, '&signcolumn', 'no')

    let height = &lines - 3
    let width = float2nr(&columns - (&columns * 2 / 10))
    let col = float2nr((&columns - width) / 2)

    let opts = {
          \ 'relative': 'editor',
          \ 'row': 1,
          \ 'col': col,
          \ 'width': width,
          \ 'height': height,
          \ 'style': 'minimal',
          \ }

    let win = nvim_open_win(buf, v:true, opts)
    call setwinvar(win, '&number', 0)
  endfunction
endif

let g:fzf_command_prefix = 'Fzf'

let g:fzf_ag_options = '--hidden'

let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit',
      \ }

let g:fzf_colors = {
      \ 'fg': ['fg', 'Normal'],
      \ 'bg': ['bg', 'Normal'],
      \ 'hl': ['fg', 'Comment'],
      \ 'fg+': ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
      \ 'bg+': ['bg', 'CursorLine', 'CursorColumn'],
      \ 'hl+': ['fg', 'Statement'],
      \ 'info': ['fg', 'PreProc'],
      \ 'border': ['fg', 'Ignore'],
      \ 'prompt': ['fg', 'Conditional'],
      \ 'pointer': ['fg', 'Exception'],
      \ 'marker': ['fg', 'Keyword'],
      \ 'spinner': ['fg', 'Label'],
      \ 'header': ['fg', 'Comment']
      \ }

command! -bang -nargs=* FzfAg call fzf#vim#ag(<q-args>, g:fzf_ag_options, <bang>0)

function! s:run_fzf_ag()
  let l:input_value = input('Pattern: ')
  if l:input_value == ''
    return
  endif
  execute 'FzfAg' l:input_value
endfunction

function! s:run_fzf_files_in_current_dir()
  execute 'FzfFiles' expand('%:h')
endfunction

nnoremap <silent> <Space>p :<C-u>FzfGFiles -co --exclude-standard<CR>
nnoremap <silent> <Space>f :<C-u>FzfFiles<CR>
nnoremap <silent> <Space>. :<C-u>call <SID>run_fzf_files_in_current_dir()<CR>
nnoremap <silent> <Space>g :<C-u>call <SID>run_fzf_ag()<CR>
nnoremap <silent> <Space>s :<C-u>FzfGFiles?<CR>
nnoremap <silent> <Space>b :<C-u>FzfBuffers<CR>
nnoremap <silent> <Space>l :<C-u>FzfLines<CR>

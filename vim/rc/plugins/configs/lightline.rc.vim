scriptencoding utf-8

let g:lightline = {
\   'colorscheme': 'hybrid',
\   'active': {
\     'left': [['mode', 'paste'], ['readonly', 'git_branch', 'filename', 'modified']],
\     'right': [['lineinfo'], ['filetype'], ['fileencoding', 'fileformat']]
\   },
\   'inactive': {
\     'left': [['readonly', 'filename', 'modified']],
\     'right': [['lineinfo'], ['filetype']]
\   },
\   'component_function': {
\     'mode': 'LightLineMode',
\     'filename': 'LightLineFilename',
\     'readonly': 'LightLineReadonly',
\     'modified': 'LightLineModified',
\     'fileformat': 'LightLineFileformat',
\     'filetype': 'LightLineFiletype',
\     'fileencoding': 'LightLineFileencoding',
\     'git_branch': 'LightLineGitBranch',
\   },
\ }

let g:lightline#compactize_width = 80
function! s:should_compactize()
  return winwidth(0) < g:lightline#compactize_width
endfunction

function! s:truncate_string(str, width)
  let l:width = a:width - 1

  if l:width <= 0
    return ''
  endif

  if len(a:str) <= l:width
    return a:str
  endif

  return '#' . a:str[-(l:width):]
endfunction

function! LightLineMode()
  let l:modename = lightline#mode()
  return s:should_compactize() ? l:modename[0] : l:modename
endfunction

function! LightLineFilename()
  if &filetype =~# 'unite'
    return fnamemodify(matchstr(unite#get_status_string(), 'directory:\s\zs.\+'), ':~')
  end

  return s:truncate_string(expand('%'), winwidth(0) - 35)
endfunction

function! LightLineReadonly()
  if &filetype =~# 'help'
    return '?'
  end

  if &readonly
    return '×'
  end

  return ''
endfunction

function! LightLineModified()
  if &filetype =~# 'help'
    return ''
  end

  if &modified
    return '+'
  end

  if !&modifiable
    return '-'
  end

  return ''
endfunction

function! LightLineFileformat()
  if s:should_compactize()
    return ''
  endif

  return &fileformat
endfunction

function! LightLineFiletype()
  if &filetype ==# ''
    return 'no ft'
  endif

  return &filetype
endfunction

function! LightLineFileencoding()
  if s:should_compactize()
    return ''
  endif

  if &fileencoding ==# ''
    return &encoding
  endif

  return &fileencoding
endfunction

function! LightLineGitBranch()
  if s:should_compactize() || !exists('*fugitive#head')
    return ''
  endif

  return fugitive#head()
endfunction

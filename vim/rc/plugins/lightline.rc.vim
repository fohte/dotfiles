let g:lightline = {
\   'colorscheme': 'hybrid',
\   'active': {
\     'left': [['mode', 'paste'], ['readonly', 'git_branch', 'filename', 'modified'], ['anzu']],
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
\     'anzu': 'LightLineAnzu',
\     'git_branch': 'LightLineGitBranch',
\   },
\ }
let g:lightline#compactize_width = 80
function! s:should_compactize()
  return winwidth(0) < g:lightline#compactize_width
endfunction

function! LightLineMode()
  let modename = lightline#mode()
  return s:should_compactize() ? modename[0] : modename
endfunction

function! LightLineFilename()
  if &filetype =~ 'unite'
    return fnamemodify(matchstr(unite#get_status_string(), 'directory:\s\zs.\+'), ':~')
  else
    return s:should_compactize() ? expand('%:t') : expand('%')
  endif
endfunction

function! LightLineReadonly()
  if &filetype =~ 'help'
    return '?'
  elseif &readonly
    return '×'
  else
    return ''
  endif
endfunction

function! LightLineModified()
  if &filetype =~ 'help'
    return ''
  elseif &modified
    return '+'
  elseif !&modifiable
    return '-'
  else
    return ''
  endif
endfunction

function! LightLineFileformat()
  return s:should_compactize() ? '' : &fileformat
endfunction

function! LightLineFiletype()
  return &filetype !=# '' ? &filetype : 'no ft'
endfunction

function! LightLineFileencoding()
  return s:should_compactize() ? '' : (&fenc !=# '' ? &fenc : &enc)
endfunction

function! LightLineGitBranch()
  if exists('*fugitive#head')
    return s:should_compactize() ? '' : fugitive#head()
  else
    return ''
  endif
endfunction

function! LightLineAnzu()
  return s:should_compactize() ? '' : anzu#search_status()
endfunction

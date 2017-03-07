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
\     'filename': 'LightLineFilename',
\     'readonly': 'LightLineReadonly',
\     'modified': 'LightLineModified',
\     'anzu': 'anzu#search_status',
\     'git_branch': 'LightLineGitBranch',
\   },
\   'separator': { 'left': '⮀', 'right': '⮂' },
\   'subseparator': { 'left': '⮁', 'right': '⮃' },
\ }

function! LightLineFilename()
  if &filetype =~ 'unite'
    return fnamemodify(matchstr(unite#get_status_string(), 'directory:\s\zs.\+'), ':~')
  else
    return expand('%')
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

function! LightLineGitBranch()
  if exists('*fugitive#head')
    return '⭠ ' . fugitive#head()
  else
    return ''
  endif
endfunction

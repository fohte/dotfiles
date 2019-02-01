scriptencoding utf-8

" Material Dark Theme
let s:black = '#212121'
let s:red1 = '#f07178'
let s:red2 = '#ff5370'
let s:green = '#c3e88d'
let s:yellow = '#ffcb6b'
let s:blue = '#82aaff'
let s:purple = '#c792ea'
let s:cyan = '#89ddff'
let s:white = '#b7bdc0'
let s:gray1 = '#212121'
let s:gray2 = '#292929'
let s:gray3 = '#474646'

let s:fg = s:white
let s:bg = s:black

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

let s:p.normal.left = [ [ s:bg, s:blue, 'bold' ], [ s:fg, s:gray3 ] ]
let s:p.normal.middle = [ [ s:fg, s:gray2 ] ]
let s:p.inactive.left = [ [ s:gray3,  s:bg ], [ s:gray3, s:bg ] ]
let s:p.inactive.middle = [ [ s:gray3, s:gray1 ] ]
let s:p.inactive.right = [ [ s:gray3, s:bg ], [ s:gray3, s:bg ] ]
let s:p.insert.left = [ [ s:bg, s:green, 'bold' ], [ s:fg, s:gray3 ] ]
let s:p.replace.left = [ [ s:bg, s:red1, 'bold' ], [ s:fg, s:gray3 ] ]
let s:p.visual.left = [ [ s:bg, s:purple, 'bold' ], [ s:fg, s:gray3 ] ]

" Common
let s:p.normal.right = [ [ s:bg, s:blue, 'bold' ], [ s:bg, s:blue, 'bold' ] ]
let s:p.normal.error = [ [ s:red2,   s:bg ] ]
let s:p.normal.warning = [ [ s:yellow, s:bg ] ]
let s:p.insert.right = [ [ s:bg, s:green, 'bold' ], [ s:bg, s:green, 'bold' ] ]
let s:p.replace.right = [ [ s:bg, s:red1, 'bold' ], [ s:bg, s:red1, 'bold' ] ]
let s:p.visual.right = [ [ s:bg, s:purple, 'bold' ], [ s:bg, s:purple, 'bold' ] ]
let s:p.tabline.left = [ [ s:fg, s:gray3 ] ]
let s:p.tabline.tabsel = [ [ s:bg, s:purple, 'bold' ] ]
let s:p.tabline.middle = [ [ s:gray3, s:gray2 ] ]
let s:p.tabline.right = [ [ s:bg, s:red1, 'bold' ] ]

let g:lightline#colorscheme#MaterialDark#palette = lightline#colorscheme#fill(s:p)

let g:lightline = {
\   'colorscheme': 'MaterialDark',
\   'active': {
\     'left': [['mode', 'paste'], ['readonly', 'filename', 'modified']],
\     'right': [['lineinfo'], ['filetype'], ['fileencoding', 'fileformat']]
\   },
\   'inactive': {
\     'left': [['readonly', 'filename', 'modified']],
\     'right': [[], ['filetype']]
\   },
\   'component_function': {
\     'mode': 'LightLineMode',
\     'filename': 'LightLineFilename',
\     'readonly': 'LightLineReadonly',
\     'modified': 'LightLineModified',
\     'fileformat': 'LightLineFileformat',
\     'filetype': 'LightLineFiletype',
\     'fileencoding': 'LightLineFileencoding',
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
  return l:modename[0]
endfunction

function! LightLineFilename()
  return s:truncate_string(fnamemodify(expand('%'), ':~:.'), winwidth(0) - 35)
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

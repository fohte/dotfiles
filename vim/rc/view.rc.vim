syntax on

function! s:my_color_settings()
  hi clear Search
  hi link Search IncSearch
  hi clear MatchParen
  hi link MatchParen Type
  hi clear CursorLineNr
  hi link CursorLineNr Comment
endfunction

augroup MyColorSettings
  autocmd!
  autocmd ColorScheme * call s:my_color_settings()
augroup END

augroup RestoreGuiCursor
  autocmd!
  autocmd VimLeave * set guicursor=a:block-blinkon0
augroup END

set background=dark
let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1
colorscheme hybrid

set number
set title
set noshowmode
set laststatus=2
set cursorline

set list

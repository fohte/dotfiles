syntax on

function! s:my_color_settings()
  hi! link Search IncSearch
  hi! link MatchParen Function
  hi! link CursorLineNr Comment
endfunction

augroup MyColorSettings
  autocmd!
  autocmd ColorScheme * call s:my_color_settings()
augroup END

augroup RestoreGuiCursor
  autocmd!
  autocmd VimLeave * set guicursor=a:block-blinkon0
augroup END

set termguicolors
colorscheme iceberg

set number
set title
set noshowmode
set laststatus=2

set list

set synmaxcol=200

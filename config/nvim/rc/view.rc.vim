syntax on

function! s:my_color_settings()
  hi! IncSearch gui=none guibg=#444444 guifg=none
  hi! link Search IncSearch

  hi! Visual guifg=none

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
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

colorscheme material

set number
set title
set noshowmode
set laststatus=2

set list
set nowrap
set listchars+=precedes:<,extends:>

set synmaxcol=1000

set completeopt-=preview

set previewheight=7

" always show the sign column even if no sign have been appeared
" for example diagnostics of coc.nvim
set signcolumn=yes

set nofoldenable

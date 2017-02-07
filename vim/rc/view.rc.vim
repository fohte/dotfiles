syntax on

set background=dark
let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1
colorscheme hybrid

augroup MyColorSettings
  autocmd!
  autocmd ColorScheme * highlight Search ctermfg=None guifg=None ctermbg=None guibg=None cterm=reverse gui=reverse
augroup END

set number
set title
set noshowmode
set laststatus=2

set list

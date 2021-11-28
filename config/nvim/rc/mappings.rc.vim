noremap j gj
noremap k gk
noremap <S-h> ^
noremap <S-l> $
nnoremap x "_x
vnoremap > >gv
vnoremap < <gv
nnoremap <silent> <ESC> :nohlsearch<CR>
nnoremap <C-z> <Nop>

cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

inoremap <C-j> <Nop>
inoremap <C-k> <Nop>

" assign `<C-q>` to the macro to use `q` for quickfix shortcuts
noremap Q q

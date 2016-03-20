nnoremap Q <Nop>
nnoremap s <Nop>
nnoremap # <Nop>

noremap j gj
noremap k gk
noremap <S-h> ^
noremap <S-l> $
nnoremap ; :
vnoremap > >gv
vnoremap < <gv

noremap G Gzz
noremap <C-f> <C-f>zz
noremap <C-b> <C-b>zz
noremap <C-u> <C-u>zz
noremap <C-d> <C-d>zz
noremap n nzz

" For Tab
nnoremap [Tab] <Nop>
nmap t [Tab]
for n in range(1, 9)
  execute 'nnoremap <silent> [Tab]'.n ':<C-u>tabnext'.n.'<CR>'
endfor
map <silent> [Tab]n :tabnew<CR>
map <silent> [Tab]h :tabprevious<CR>
map <silent> [Tab]l :tabnext<CR>

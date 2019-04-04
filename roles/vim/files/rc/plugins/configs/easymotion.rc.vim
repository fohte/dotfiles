let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
let g:EasyMotion_enter_jump_first = 1
let g:EasyMotion_space_jump_first = 1
let g:EasyMotion_prompt = '> '
let g:EasyMotion_verbose = 0
let g:EasyMotion_keys = 'uhetonasid'

noremap ' <Nop>
map 'f <Plug>(easymotion-f)
map 'F <Plug>(easymotion-F)
map 'l <Plug>(easymotion-bd-jk)
map 'j <Plug>(easymotion-j)
map 'k <Plug>(easymotion-k)
map 'b <Plug>(easymotion-b)
map 'B <Plug>(easymotion-B)
map 'w <Plug>(easymotion-w)
map 'W <Plug>(easymotion-W)

noremap <C-w><C-w> <Nop>
map <C-w><C-w> <Plug>(easymotion-overwin-line)

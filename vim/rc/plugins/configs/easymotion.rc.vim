let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
let g:EasyMotion_enter_jump_first = 1
let g:EasyMotion_space_jump_first = 1
let g:EasyMotion_prompt = '> '
let g:EasyMotion_verbose = 0
let g:EasyMotion_keys = 'uhetonasid'

noremap ' <Nop>
map 'f <Plug>(easymotion-bd-f)
map 's <Plug>(easymotion-s)
map 'c <Plug>(easymotion-bd-fl)
map 'l <Plug>(easymotion-bd-jk)
map 'j <Plug>(easymotion-j)
map 'k <Plug>(easymotion-k)
map 'w <Plug>(easymotion-w)
nmap ',w <Plug>(easymotion-overwin-w)
nmap ',c <Plug>(easymotion-overwin-k)

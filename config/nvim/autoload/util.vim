let g:util#nvim_rc_dir = resolve(expand('~/.config/nvim/rc'))

function! util#source_rc(path) abort
  let l:abspath = resolve(expand(g:util#nvim_rc_dir . '/' . a:path))
  execute 'source' fnameescape(l:abspath)
endfunction

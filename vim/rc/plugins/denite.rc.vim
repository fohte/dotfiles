call denite#custom#alias('source', 'file_rec/git', 'file_rec')
call denite#custom#var('file_rec/git', 'command',
      \ ['git', 'ls-files', '-co', '--exclude-standard'])

if executable('ag')
  " call denite#custom#var('grep', 'command',
  "       \ ['ag', '--ignore-case', '--hidden', '--nocolor', '--nogroup', '--ignore', '.git'])
  call denite#custom#var('grep', 'command', ['ag'])
  call denite#custom#var('grep', 'default_opts',
        \ ['-i', '--vimgrep', '--hidden'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'pattern_opt', [])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'final_opts', [])
endif

call denite#custom#map('insert', '<C-j>', '<denite:move_to_next_line>')
call denite#custom#map('insert', '<C-k>', '<denite:move_to_previous_line>')
call denite#custom#map('normal', '<C-s>', '<denite:do_action:split>')
call denite#custom#map('insert', '<C-s>', '<denite:do_action:split>')
call denite#custom#map('normal', '<C-v>', '<denite:do_action:vsplit>')
call denite#custom#map('insert', '<C-v>', '<denite:do_action:vsplit>')

nnoremap [denite] <Nop>
nmap <Space> [denite]
map <silent> [denite]p :<C-u>Denite file_rec/git<CR>
map <silent> [denite]f :<C-u>Denite file_rec<CR>
map <silent> [denite]b :<C-u>Denite buffer<CR>
map <silent> [denite]g :<C-u>Denite grep<CR>

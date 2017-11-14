call denite#custom#alias('source', 'file_rec/git', 'file_rec')
call denite#custom#var('file_rec/git', 'command',
      \ ['git', 'ls-files', '-co', '--exclude-standard'])

call denite#custom#option('default', 'highlight_matched_char', 'Underlined')
call denite#custom#option('default', 'highlight_matched_range', 'cleared')

if executable('ag')
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

call denite#custom#source('_', 'sorters', ['sorter_rank'])

call denite#custom#source('file_old', 'converters', ['converter_relative_word'])
call denite#custom#source('file_old', 'matchers', ['matcher_project_files'])

call denite#custom#option('default', 'vertical_preview', 1)

map <silent> <Leader>p :<C-u>Denite file_rec/git<CR>
map <silent> <Leader>f :<C-u>Denite file_rec<CR>
map <silent> <Leader>. :<C-u>DeniteBufferDir file_rec<CR>
map <silent> <Leader>o :<C-u>Denite -auto-preview file_old<CR>
map <silent> <Leader>g :<C-u>Denite -no-empty grep<CR>
map <silent> <Leader>r :<C-u>Denite -resume<CR>
map <silent> <Leader>t :<C-u>Denite -split=vertical -buffer-name=tags outline<CR>
map <silent> <Leader>h :<C-u>Denite -resume -immediately -cursor-pos=-1<CR>
map <silent> <Leader>l :<C-u>Denite -resume -immediately -cursor-pos=+1<CR>

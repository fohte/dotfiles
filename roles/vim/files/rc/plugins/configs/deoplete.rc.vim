let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_camel_case = 0
let g:deoplete#max_list = 20
let g:deoplete#enable_refresh_always = 0
let g:deoplete#auto_complete_start_length = 1
let g:deoplete#auto_complete_delay = 50
let g:deoplete#file#enable_buffer_path = 1

set completeopt+=noinsert,noselect

call deoplete#custom#source('omni', 'input_patterns', {
\   'ruby': ['\w+', '[^. *\t]\.\w*', '[a-zA-Z_]\w*::'],
\   'rust': ['\w+', '[^. *\t]\.\w*', '[a-zA-Z_]\w*::'],
\   'javascript': ['\w+', '[^. *\t]\.\w*'],
\   'python': ['\w+', '[^. *\t]\.\w*'],
\   'typescript': ['\w+', '[^. *\t]\.\w*'],
\   'dockerfile': ['\w+'],
\ })

set omnifunc=lsp#complete

call deoplete#custom#option('omni_patterns', {
\  'complete_method': 'omnifunc',
\  'terraform': '[^ *\t"{=$]\w*',
\ })

call deoplete#custom#source('_', 'matchers', ['matcher_full_fuzzy', 'matcher_length'])
call deoplete#custom#source('_', 'converters', [
  \ 'converter_remove_paren',
  \ 'converter_auto_delimiter',
  \ 'converter_remove_overlap',
  \ 'converter_truncate_abbr',
  \ 'converter_truncate_menu',
  \ ])
call deoplete#custom#source('_', 'sorters', ['sorter_word'])
call deoplete#custom#source('omni', 'rank', 1000)

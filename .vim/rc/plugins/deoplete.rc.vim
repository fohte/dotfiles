let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_camel_case = 0
let g:deoplete#max_list = 10
let g:deoplete#enable_refresh_always = 1
let g:deoplete#auto_complete_start_length = 2
let g:deoplete#auto_complete_delay = 0

let g:deoplete#keyword_patterns = {}
let g:deoplete#keyword_patterns._ = '[a-zA-Z_]\k*'

let g:deoplete#omni#input_patterns = {}
let g:deoplete#omni#input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'

inoremap <expr> <TAB>   pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
inoremap <expr> <BS>    deoplete#mappings#close_popup()."\<C-h>"

call deoplete#custom#set('_', 'matchers', ['matcher_full_fuzzy', 'matcher_length'])
call deoplete#custom#set('_', 'disabled_syntaxes', ['Comment', 'String'])
call deoplete#custom#set('_', 'converters', [
  \ 'converter_auto_paren',
  \ 'converter_auto_delimiter',
  \ 'converter_remove_overlap',
  \ 'converter_truncate_abbr',
  \ 'converter_truncate_menu',
  \ ])

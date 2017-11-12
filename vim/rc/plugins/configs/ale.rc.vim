let g:ale_lint_on_text_changed = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1

let g:ale_linters = {
\   'go': ['gometalinter', 'gofmt'],
\ }

" javascript
let g:ale_javascript_eslint_executable = 'eslint_d'
let g:ale_javascript_eslint_use_global = 1

" go
let g:ale_go_gometalinter_options = '--disable-all --enable=vet --enable=gotype'

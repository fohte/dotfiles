let g:ale_set_signs = 0
let g:ale_lint_on_text_changed = 'always'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1
let g:ale_javascript_prettier_use_local_config = 1
let g:ale_go_gometalinter_options = '--disable-all --enable=vet --enable=gotype'

let g:ale_linter_aliases = {
\   'javascript': ['css'],
\   'typescript': ['css'],
\ }

let g:ale_linters = {
\   'go': ['gometalinter', 'gofmt'],
\   'typescript': ['tslint', 'stylelint'],
\ }

let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'typescript': ['prettier'],
\   'json': ['prettier'],
\   'css': ['prettier'],
\   'scss': ['prettier'],
\   'ruby': ['rubocop'],
\   'rust': ['rustfmt'],
\ }

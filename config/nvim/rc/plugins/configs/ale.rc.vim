let g:ale_set_signs = 1
let g:ale_sign_column_always = 1
let g:ale_lint_on_text_changed = 'always'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1
let g:ale_go_gometalinter_options = '--disable-all --enable=vet --enable=gotype'

" デフォルトの '' だと `-i 2` オプションが付与されてしまうので無効化する
let g:ale_sh_shfmt_options = ' '

let g:ale_linters = {
\   'go': ['gometalinter', 'gofmt'],
\   'javascript': ['eslint', 'tslint'],
\   'jsonnet': ['jsonnet-lint'],
\   'python': ['flake8'],
\   'terraform': ['tflint'],
\   'typescript': ['tsserver', 'tslint', 'stylelint'],
\ }

let g:ale_fixers = {
\   'jsonnet': ['jsonnetfmt'],
\   'python': ['isort', 'black'],
\   'ruby': ['rubocop'],
\   'rust': ['rustfmt'],
\   'sh': ['shfmt'],
\   'terraform': ['terraform'],
\ }

nnoremap <silent> <F10> :ALEFix<CR>
inoremap <silent> <F10> <C-o>:ALEFix<CR>

let g:ale_pattern_options = {
\   '.*/node_modules/.*': { 'ale_enabled': 0 },
\ }

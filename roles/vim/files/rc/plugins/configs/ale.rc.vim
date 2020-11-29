let g:ale_set_signs = 1
let g:ale_sign_column_always = 1
let g:ale_lint_on_text_changed = 'always'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1

let g:ale_javascript_prettier_use_local_config = 1
let g:ale_go_gometalinter_options = '--disable-all --enable=vet --enable=gotype'
let g:ale_sh_shfmt_options = '-sr -i 2'

let g:ale_linters = {
\   'css': ['stylelint'],
\   'go': ['gometalinter', 'gofmt'],
\   'javascript': ['eslint'],
\   'python': ['flake8'],
\   'scss': ['stylelint'],
\   'typescript': ['eslint', 'stylelint'],
\ }

let g:ale_fixers = {
\   'css': ['stylelint', 'prettier'],
\   'graphql': ['prettier'],
\   'javascript': ['prettier'],
\   'json': ['prettier'],
\   'json5': ['prettier'],
\   'markdown': ['prettier'],
\   'python': ['isort', 'black'],
\   'ruby': ['rubocop'],
\   'rust': ['rustfmt'],
\   'scss': ['stylelint', 'prettier'],
\   'sh': ['shfmt'],
\   'typescript': ['eslint', 'prettier'],
\   'yaml': ['prettier'],
\   'mdx': ['prettier'],
\ }

nnoremap <silent> <F10> :ALEFix<CR>
inoremap <silent> <F10> <C-o>:ALEFix<CR>

let g:ale_pattern_options = {
\   '.*/node_modules/.*': { 'ale_enabled': 0 },
\ }

" iidx.io で frontend 下の prettier と root の prettier
" のバージョンが衝突するので常にグローバルのものを使う
let g:ale_javascript_prettier_use_global = 1

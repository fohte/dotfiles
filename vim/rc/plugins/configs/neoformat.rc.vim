augroup config_neoformat
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END

augroup config_neoformat_prettier
  autocmd!
  autocmd FileType javascript,typescript,css,less,scss,json,graphql,markdown
        \ setlocal formatprg=prettier_dnc\ --local-only\ --pkg-conf\ --fallback
augroup END

let g:neoformat_try_formatprg = 1
let g:neoformat_only_msg_on_error = 1

scriptencoding utf-8

function! s:replace_punctuation() abort
  %s/、/，/ge
  %s/。/．/ge
endfunction

augroup filetype_tex
  au! BufWritePre *.tex call <SID>replace_punctuation()
augroup AND

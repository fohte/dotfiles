if exists('b:current_syntax')
  finish
endif

" inherit markdown syntax
runtime! syntax/markdown.vim
unlet! b:current_syntax

" thread header: <!-- thread: PRT_xxx path: file.rs:42 -->
syn match prReviewThreadHeader /^<!-- thread:.\+-->$/

" comment delimiters: <!-- comment: @author timestamp --> and <!-- /comment -->
syn match prReviewCommentDelim /^<!-- comment:.\+-->$/
syn match prReviewCommentDelim /^<!-- \/comment -->$/

" diff delimiters: <!-- diff --> and <!-- /diff -->
syn match prReviewDiffDelim /^<!-- diff -->$/
syn match prReviewDiffDelim /^<!-- \/diff -->$/

" resolve checkbox
syn match prReviewUnresolved /^- \[ \] resolve$/
syn match prReviewResolved /^- \[x\] resolve$/

let b:current_syntax = 'pr_review'

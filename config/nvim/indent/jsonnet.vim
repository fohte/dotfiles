" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal nosmartindent

" use json indent (defined by $VIMRUNTIME/indent/json.vim)
setlocal indentexpr=GetJSONIndent(v:lnum)
setlocal indentkeys=0{,0},0),0[,0],!^F,o,O,e

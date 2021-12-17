" Vim syntax file
" Language: Abby (*.ab) syntax file
" Maintainer: quintik

if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "abby"

syntax case match

syn keyword abbyKeywords abbr expr
syn keyword abbyEsc Esc contained

syn match abbyIdent /\s\k\+\s/hs=s+1,he=e-1

" from '#' to end of line
syn region abbyComment start="#"       end="\n"
" open/close angle brackets for special chars like <Esc>/<CR>/etc.
syn region abbyCharKey start=/</       end=/>/          contains=abbyEsc contained
" <Esc> to enter normal mode, and then common keys that go into insert mode
syn region abbyNMode   start=/<Esc>/   end=/[iaoIAOSC]/ contains=abbyCharKey

" start with {, skip nested {..}, end with }, use '\{-}' for non-greedy match
syn region abbyBlock start=/{/hs=s+1 skip=/{.\{-}}/ end=/}/he=e-1 contains=ALLBUT,abbyKeywords,abbyIdent

hi def link abbyKeywords  Statement
hi def link abbyIdent     Identifier
hi def link abbyBlock     Constant
hi def link abbyComment   Comment
hi def link abbyCharKey   Comment
hi def link abbyEsc       Number
hi def link abbyNMode     Number


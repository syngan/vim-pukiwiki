"=============================================================================
" @AUTHOR: syngan
" @License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

scriptencoding euc-jp

runtime! syntax/help.vim

hi def link pukiwikiBracketName Underlined
"hi def link Head Directory
"hi def link VimPHPURL Underlined
hi def link pukiwikiBodyDelim LineNr
"hi def link NotEditable WarningMsg


"syntax match VimPHPURL display "s\?https\?:\/\/[-_.!~*'()a-zA-Z0-9;/?:@&=+$,%#]\+\/vim.php[-\./0-9a-zA-Z]*"
"syntax match BracketName display "\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]"
syntax match pukiwikiBracketName display "\[\[\_.\{-}\]\]"
syntax match pukiwikiBodyDelim display "^-\{3,}.*--$"
"syntax match Head display "\\\@<!|[^"*|]\+|"
"syntax match NotEditable display "===== Not Editable ====="


syntax match pukiwikiBlockElement   "^#[A-Za-z0-9_]*"
syntax match pukiwikiInlineElement	"&[A-Za-z0-9_]*"
syntax match pukiwikiPre            "^ .*$"
syntax match pukiwikiH1             "^\*[^\*]*$"
syntax match pukiwikiH2             "^\*\*[^\*]*$"
syntax match pukiwikiH3             "^\*\*\*[^\*]*$"


hi def link pukiwikiBlockElement	Function
hi def link pukiwikiInlineElement	Function
hi def link pukiwikiH1 String
hi def link pukiwikiH2 String
hi def link pukiwikiH3 String

hi def link pukiwikiPre Statement


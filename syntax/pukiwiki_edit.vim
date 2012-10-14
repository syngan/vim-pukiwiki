" $Id: pukiwiki_edit.vim 10 2008-07-27 07:34:08Z ishii $

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


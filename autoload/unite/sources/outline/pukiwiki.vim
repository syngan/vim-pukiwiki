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

function! unite#sources#outline#pukiwiki#outline_info()
	return s:outline_info
endfunction


let s:outline_info = {
\	'heading' : '^\*\{1,3}'
\}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
	let heading = {
	\	'word' : a:heading_line,
	\   'level' : 1,
	\   'type' : 'generic',
	\}

	if heading.word =~ '^\*\{3}.*'
		let heading.level = 3
	elseif heading.word =~ '^\*\{2}.*'
		let heading.level = 2
	elseif heading.word =~ '^\*\{1}.*'
		let heading.level = 1
	else
		let heading.level = 4
	endif
	let heading.word = substitute(heading.word, '^\**', '', '')
	let heading.word = substitute(heading.word, '\[#[a-z0-9]*\]$', '', '')

	return heading
endfunction




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

let s:save_cpo = &cpo
set cpo&vim

" source $B$rMQ0U(B
let s:uni_puki = {
	\ 'name': 'pukiwiki/history',
	\ 'default_action' : 'open_page',
	\ 'action_table' : {},
	\ 'alias_table' : { 'execute' : 'open_page' },
	\ 'default_kind' : 'command',
	\}
" $B$3$l$@$HF0$+$J$$(B
"	\ 'alias_table' : { 'open' : 'open_page' },
"	\ 'default_kind' : 'openable',

 
function! s:uni_puki.gather_candidates(args, context) "{{{
" $B8uJd$O(B history $B$N%j%9%H(B
" history $B$NMWAG$O%j%9%H$G(B [site, page, others]
	let history = pukiwiki#get_history_list()

	" copy $B$7$J$$$H%j%9%H$,2u$l$k(B.
	" $B4X?tEO$9$?$a$K(B v:val $B$bJ]B8(B
    return map(copy(history), "{
	\ 'word' :  v:val[0] . ' -- ' . v:val[1], 
	\ 'action__command' : 'PukiWiki ' . v:val[0] . ' ' . v:val[1],
	\ 'source' : 'pukiwiki/history',
	\ 'pukiwiki_history' : v:val,
	\}")
endfunction "}}}

" open_page $B$N(B action $B$NDj5A(B
let s:uni_puki.action_table.open_page = {
	\ 'description' : 'open the selected page',
	\ 'is_quit' : 1,
	\ 'is_selectable' : 0,
	\}

function! s:uni_puki.action_table.open_page.func(candidates) "{{{
	" pukiwiki#PukiWiki() $B$G%Z!<%8$r3+$/(B
	" $B%Z!<%8L>$K6uGr$,4^$^$l$?$H$-$K:#$N(B action__command $B$N@_Dj$G$OF0:n$7$J$$(B.
	let history = a:candidates.pukiwiki_history
	call pukiwiki#PukiWiki(history[0], history[1])
"	let command = a:candidates.action__command
"	let type = get(a:candidates, 'action__type', ':')
"	execute type . comand
endfunction "}}}

function! unite#sources#pukiwiki#define() "{{{
	" $BEPO?(B. g:pukiwiki_config $B$,Dj5A$5$l$F$$$J$$>l9g$K$O(B
	" $BF0:n$7$F$$$J$$$O$:$J$N$GEPO?$7$J$$(B
	if !exists('g:pukiwiki_config')
		return {}
	endif
	return s:uni_puki
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
"

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

" pukiwiki/history {{{
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
	\ 'word' :  v:key . ' ' . v:val[0] . ' -- ' . v:val[1],
	\ 'action__command' : 'PukiWiki ' . v:val[0] . ' ' . v:val[1],
	\ 'source' : 'pukiwiki/history',
	\ 'pukiwiki_history' : v:val,
	\ 'pukiwiki_index' : v:key,
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

" delete $B$OJ#?tA*Br2DG=(B (is_selectable=1)
let s:uni_puki.action_table.delete = {
	\ 'description' : 'delete the selected page from the history',
	\ 'is_quit' : 0,
	\ 'is_selectable' : 1,
	\ 'is_invalidate_cache' : 1,
	\}

function! s:uni_puki.action_table.delete.func(candidates) "{{{
	" is_selectable = 1 $B$N>l9g$O(B candidates $B$,%j%9%H$K$J$k$i$7$$(B.
	let idx = len(a:candidates) - 1
	let history = pukiwiki#get_history_list()

	" candidates $B$OA*Br=g=x$K0MB8$;$:!">:=g$G$/$k$H2>Dj(B.
	while idx >= 0
		let index = a:candidates[idx].pukiwiki_index
		call remove(history, index)
		let idx = idx - 1
	 endwhile
endfunction "}}}
" }}}

" pukiwiki/menu {{{
let s:uni_menu = {
	\ 'name': 'pukiwiki/menu',
	\ 'description': 'menu of PukiWiki',
	\ 'default_action' : 'execute',
	\ 'action_table' : {},
	\ 'default_kind' : 'command',
\}

function! s:uni_menu.gather_candidates(args, context) "{{{
" $B8uJd$O(B pukiwiki $B$N%a%K%e!<8GDj(B
" [[$B%H%C%W(B]] [[$BE:IU(B]] [[$B%j%m!<%I(B]] [[$B?75,(B]] [[$B0lMw(B]] [[$BC18l8!:w(B]] [[$B:G=*99?7(B]] [[$B%X%k%W(B]]
	let cand = []
	call add(cand, {
	\	'word' : 'top page',
	\	'action__command' : 'PukiWikiJumpMenu top',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'attached files',
	\	'action__command' : 'PukiWikiJumpMenu attach',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'reload',
	\	'action__command' : 'PukiWikiJumpMenu reload',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'new page',
	\	'action__command' : 'PukiWikiJumpMenu new',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'page list',
	\	'action__command' : 'PukiWikiJumpMenu list',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'search',
	\	'action__command' : 'PukiWikiJumpMenu search',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'recent changes',
	\	'action__command' : 'PukiWikiJumpMenu recent',
	\   'source' : 'pukiwiki/menu',
	\})
	call add(cand, {
	\	'word' : 'help: formatting rules',
	\	'action__command' : 'PukiWikiJumpMenu help',
	\   'source' : 'pukiwiki/menu',
	\})
	return cand
endfunction

" }}}

" }}}

" pukiwiki/bookmark {{{
let s:uni_bm = {
	\ 'name': 'pukiwiki/bookmark',
	\ 'description': 'bookmark of PukiWiki',
	\ 'default_action' : 'execute',
	\ 'action_table' : {},
	\ 'default_kind' : 'command',
\}

let s:uni_bm.action_table.delete = {
	\ 'description' : 'delete the selected page from the bookmark',
	\ 'is_quit' : 0,
	\ 'is_selectable' : 1,
	\ 'is_invalidate_cache' : 1,
	\}

let s:uni_bm.action_table.moveup = {
	\ 'description' : 'move up the selected page',
	\ 'is_quit' : 0,
	\ 'is_selectable' : 0,
	\ 'is_invalidate_cache' : 1,
	\}

let s:uni_bm.action_table.movedown = {
	\ 'description' : 'move down the selected page',
	\ 'is_quit' : 0,
	\ 'is_selectable' : 0,
	\ 'is_invalidate_cache' : 1,
	\}

function! s:uni_bm.action_table.delete.func(candidates) "{{{
	" is_selectable = 1 $B$N>l9g$O(B candidates $B$,%j%9%H$K$J$k$i$7$$(B.

	if !exists('g:pukiwiki_bookmark')
		return
	endif

	let lines = readfile(g:pukiwiki_bookmark)
	if lines[0] != "pukiwiki.bookmark.v1."
		return
	endif

	" candidates $B$OA*Br=g=x$K0MB8$;$:!">:=g$G$/$k$H2>Dj(B.
	let idx = len(a:candidates) - 1
	while idx >= 0
		let index = a:candidates[idx].pukiwiki_index
		call remove(lines, index)
		let idx = idx - 1
	 endwhile

	 call writefile(lines, g:pukiwiki_bookmark)
endfunction "}}}

function! s:movecand(from, to) "{{{
	if !exists('g:pukiwiki_bookmark')
		return
	endif

	let lines = readfile(g:pukiwiki_bookmark)
	if lines[0] != "pukiwiki.bookmark.v1."
		return
	endif

	" candidates $B$OA*Br=g=x$K0MB8$;$:!">:=g$G$/$k$H2>Dj(B.
	let v = remove(lines, a:from)
	if a:to >= 0
		call insert(lines, v, a:to)
	endif

	call writefile(lines, g:pukiwiki_bookmark)
endfunction "}}}

function! s:uni_bm.action_table.moveup.func(candidates) "{{{
	let index = a:candidates.pukiwiki_index
	call s:movecand(index, index-1)
endfunction "}}}

function! s:uni_bm.action_table.movedown.func(candidates) "{{{
	let index = a:candidates.pukiwiki_index
	call s:movecand(index+1, index)
endfunction "}}}

function! s:uni_bm.gather_candidates(args, context) "{{{
	if !exists('g:pukiwiki_bookmark')
		return []
	endif

	if !filereadable(g:pukiwiki_bookmark)
		return []
	endif

	let lines = readfile(g:pukiwiki_bookmark)
	if len(lines) < 2
		return []
	endif
	if lines[0] != "pukiwiki.bookmark.v1."
		return []
	endif

	let lines = lines[1:]
	for i in range(0, len(lines)-1)
		let v = lines[i]
		let site = substitute(v, ',.*', '', '')
		let page = substitute(v, '^[^,]*,', '', '')
		let l = {}
		let l.word = page . ' @ ' . site
		" $B%9%Z!<%9$r%(%9%1!<%W$9$k(B
		let l.action__command= 'PukiWiki ' . site . ' ' . escape(page, ' ')
		let l.source = 'pukiwiki/bookmark'
		let l.pukiwiki_index = i + 1
		let lines[i] = l
	endfor

	return lines
endfunction
" }}}
" }}}

function! unite#sources#pukiwiki#define() "{{{
	" $BEPO?(B. g:pukiwiki_config $B$,Dj5A$5$l$F$$$J$$>l9g$K$O(B
	" $BF0:n$7$F$$$J$$$O$:$J$N$GEPO?$7$J$$(B
	if !exists('g:pukiwiki_config')
		return {}
	endif
	return [s:uni_puki, s:uni_menu, s:uni_bm]
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
"

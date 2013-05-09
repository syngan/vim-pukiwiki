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

let s:save_cpo = &cpo
set cpo&vim

" pukiwiki/history {{{
" source ���Ѱ�
let s:uni_puki = {
	\ 'name': 'pukiwiki/history',
	\ 'default_action' : 'open_page',
	\ 'action_table' : {},
	\ 'alias_table' : { 'execute' : 'open_page' },
	\ 'default_kind' : 'command',
	\}
" �������ư���ʤ�
"	\ 'alias_table' : { 'open' : 'open_page' },
"	\ 'default_kind' : 'openable',

function! s:uni_puki.gather_candidates(args, context) "{{{
" ����� history �Υꥹ��
" history �����Ǥϥꥹ�Ȥ� [site, page, others]
	let history = pukiwiki#get_history_list()

	" copy ���ʤ��ȥꥹ�Ȥ������.
	" �ؿ��Ϥ������ v:val ����¸
    return map(copy(history), "{
	\ 'word' :  v:key . ' ' . v:val[0] . ' -- ' . v:val[1],
	\ 'action__command' : 'PukiWiki ' . v:val[0] . ' ' . v:val[1],
	\ 'source' : 'pukiwiki/history',
	\ 'pukiwiki_history' : v:val,
	\ 'pukiwiki_index' : v:key,
	\}")
endfunction "}}}

" open_page �� action �����
let s:uni_puki.action_table.open_page = {
	\ 'description' : 'open the selected page',
	\ 'is_quit' : 1,
	\ 'is_selectable' : 0,
	\}

function! s:uni_puki.action_table.open_page.func(candidates) "{{{
	" pukiwiki#PukiWiki() �ǥڡ����򳫤�
	" �ڡ���̾�˶��򤬴ޤޤ줿�Ȥ��˺��� action__command ������Ǥ�ư��ʤ�.
	let history = a:candidates.pukiwiki_history
	call pukiwiki#PukiWiki(history[0], history[1])
"	let command = a:candidates.action__command
"	let type = get(a:candidates, 'action__type', ':')
"	execute type . comand
endfunction "}}}

" delete ��ʣ�������ǽ (is_selectable=1)
let s:uni_puki.action_table.delete = {
	\ 'description' : 'delete the selected page from the history',
	\ 'is_quit' : 0,
	\ 'is_selectable' : 1,
	\ 'is_invalidate_cache' : 1,
	\}

function! s:uni_puki.action_table.delete.func(candidates) "{{{
	" is_selectable = 1 �ξ��� candidates ���ꥹ�Ȥˤʤ�餷��.
	let idx = len(a:candidates) - 1
	let history = pukiwiki#get_history_list()

	" candidates ���������˰�¸����������Ǥ���Ȳ���.
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
" ����� pukiwiki �Υ�˥塼����
" [[�ȥå�]] [[ź��]] [[�����]] [[����]] [[����]] [[ñ�측��]] [[�ǽ�����]] [[�إ��]]
	let cand = [
	\	['top page', 'top'],
	\	['attached files', 'attach'],
	\	['reload', 'reload'],
	\	['open/create page', 'new'],
	\	['page list', 'list'],
	\	['search', 'search'],
	\	['recent changes', 'recent'],
	\	['help: formatting rules', 'help'],
	\]

	return map(cand, "{
	\	'word' : v:val[0],
	\	'action__command' : 'PukiWikiJumpMenu ' . v:val[1],
	\   'source' : 'pukiwiki/menu'}")
endfunction " }}}

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
	" is_selectable = 1 �ξ��� candidates ���ꥹ�Ȥˤʤ�餷��.

	if !exists('g:pukiwiki_bookmark')
		return
	endif

	let lines = readfile(g:pukiwiki_bookmark)
	if lines[0] != "pukiwiki.bookmark.v1."
		return
	endif

	" candidates ���������˰�¸����������Ǥ���Ȳ���.
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

	" candidates ���������˰�¸����������Ǥ���Ȳ���.
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
		" ���ڡ����򥨥������פ���
		let l.action__command = 'PukiWiki ' . site . ' ' . escape(page, ' ')
		let l.source = 'pukiwiki/bookmark'
		let l.pukiwiki_index = i + 1
		let lines[i] = l
	endfor

	return lines
endfunction
" }}}
" }}}

function! unite#sources#pukiwiki#define() "{{{
	" ��Ͽ. g:pukiwiki_config ���������Ƥ��ʤ����ˤ�
	" ư��Ƥ��ʤ��Ϥ��ʤΤ���Ͽ���ʤ�
	if !exists('g:pukiwiki_config')
		return {}
	endif
	return [s:uni_puki, s:uni_menu, s:uni_bm]
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
"

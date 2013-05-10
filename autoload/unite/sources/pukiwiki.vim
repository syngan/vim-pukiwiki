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
" source を用意
let s:uni_puki = {
	\ 'name': 'pukiwiki/history',
	\ 'default_action' : 'open_page',
	\ 'action_table' : {},
	\ 'alias_table' : { 'execute' : 'open_page' },
	\ 'default_kind' : 'command',
	\}
" これだと動かない
"	\ 'alias_table' : { 'open' : 'open_page' },
"	\ 'default_kind' : 'openable',

function! s:uni_puki.gather_candidates(args, context) "{{{
" 候補は history のリスト
" history の要素はリストで [site, page, others]
	let history = pukiwiki#get_history_list()

	" copy しないとリストが壊れる.
	" 関数渡すために v:val も保存
    return map(copy(history), "{
	\ 'word' :  v:key . ' ' . v:val[0] . ' -- ' . v:val[1],
	\ 'action__command' : 'PukiWiki ' . v:val[0] . ' ' . v:val[1],
	\ 'source' : 'pukiwiki/history',
	\ 'pukiwiki_history' : v:val,
	\ 'pukiwiki_index' : v:key,
	\}")
endfunction "}}}

" open_page の action の定義
let s:uni_puki.action_table.open_page = {
	\ 'description' : 'open the selected page',
	\ 'is_quit' : 1,
	\ 'is_selectable' : 0,
	\}

function! s:uni_puki.action_table.open_page.func(candidates) "{{{
	" pukiwiki#PukiWiki() でページを開く
	" ページ名に空白が含まれたときに今の action__command の設定では動作しない.
	let history = a:candidates.pukiwiki_history
	call pukiwiki#PukiWiki(history[0], history[1])
"	let command = a:candidates.action__command
"	let type = get(a:candidates, 'action__type', ':')
"	execute type . comand
endfunction "}}}

" delete は複数選択可能 (is_selectable=1)
let s:uni_puki.action_table.delete = {
	\ 'description' : 'delete the selected page from the history',
	\ 'is_quit' : 0,
	\ 'is_selectable' : 1,
	\ 'is_invalidate_cache' : 1,
	\}

function! s:uni_puki.action_table.delete.func(candidates) "{{{
	" is_selectable = 1 の場合は candidates がリストになるらしい.
	let idx = len(a:candidates) - 1
	let history = pukiwiki#get_history_list()

	" candidates は選択順序に依存せず、昇順でくると仮定.
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
" 候補は pukiwiki のメニュー固定
" [[トップ]] [[添付]] [[リロード]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]
	let cand = [
	\	['top page', 'top'],
	\	['attached files', 'attach'],
	\	['reload', 'reload'],
	\	['create page/open page', 'new'],
	\	['page list', 'list'],
	\	['search', 'search'],
	\	['recent changes', 'recent'],
	\	['help: formatting rules', 'help'],
	\]

	return map(cand, "{
	\	'word' : v:val[0],
	\	'action__command' : 'PukiWikiJumpMenu ' . v:val[1],
	\   'source' : 'pukiwiki/menu'}")
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
	" is_selectable = 1 の場合は candidates がリストになるらしい.

	if !exists('g:pukiwiki_bookmark')
		return
	endif

	let lines = readfile(g:pukiwiki_bookmark)
	if lines[0] != "pukiwiki.bookmark.v1."
		return
	endif

	" candidates は選択順序に依存せず、昇順でくると仮定.
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

	" candidates は選択順序に依存せず、昇順でくると仮定.
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
		" スペースをエスケープする
		let l.action__command = 'PukiWiki ' . site . ' ' . escape(page, ' ')
		let l.source = 'pukiwiki/bookmark'
		let l.pukiwiki_index = i + 1
		let lines[i] = l
	endfor

	return lines
endfunction
" }}}
" }}}

" pukiwiki/attach {{{
let s:uni_attach = {
	\ 'name': 'pukiwiki/attach',
	\ 'description': 'attach files of PukiWiki',
	\ 'default_action' : 'yank',
	\ 'action_table' : {},
	\ 'default_kind' : 'command',
\}

let s:uni_attach.hooks = {}

function! s:uni_attach.hooks.on_init(args, context) "{{{
	if exists('b:pukiwiki_info')
		let a:context.source__pw_info = b:pukiwiki_info
	else
		echo "pukiwiki.vim is not initialized"
	endif
endfunction "}}}

function! s:uni_attach.gather_candidates(args, context) "{{{
	if !has_key(a:context, 'source__pw_info')
		return []
	endif

	let b:pukiwiki_info = a:context.source__pw_info
	let site = b:pukiwiki_info["site"]
	let page = b:pukiwiki_info["page"]
	let files = pukiwiki#get_attach_files()

	return map(files, "{
	\	'word' : v:val[0],
	\	'source' : 'pukiwiki/attach',
	\	'source__pw_info' : b:pukiwiki_info,
	\}")
endfunction "}}}

let s:uni_attach.action_table.delete = {
	\ 'description' : 'delete the selected file from PukiWiki',
	\ 'is_selectable' : 0,
	\ 'is_invalidate_cache' : 1,
	\}

function! s:uni_attach.action_table.delete.func(candidates) "{{{

	let pukiwiki_info = a:candidates.source__pw_info
	let site_name = pukiwiki_info["site"]
	let page = pukiwiki_info["page"]
	let filename = a:candidates.word
	if !unite#util#input_yesno(
		\ 'Really delete "' . filename .'" at ' . page . ' @ ' . site_name)
		redraw
		echo 'canceled.'
		return
	endif
	redraw

	call pukiwiki#delete_attach_file(site_name, page, filename)
endfunction "}}}

"function! s:uni_attach.action_table.show_info = {
"	\ 'description' : 'show detail information of the attached file'
"	\ 'is_selectable' : 0,
"	\ 'is_invalidate_cache' : 0,
"	\ 'kind' : 'source',
"	\}
"
"function! s:uni_attach.action_table.show_info.func(candidates) "{{{
"
""	unite#start("pukiwiki/attach_info")
"
"	let filename = a:candidates.word
"	let site_name = a:candidates.source__pw_site_name
"	let page = a:candidates.source__pw_page
"
"endfunction " }}} 


function! unite#sources#pukiwiki#define() "{{{
	" 登録. g:pukiwiki_config が定義されていない場合には
	" 動作していないはずなので登録しない
	if !exists('g:pukiwiki_config')
		return {}
	endif
	return [s:uni_puki, s:uni_menu, s:uni_bm, s:uni_attach]
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:
"

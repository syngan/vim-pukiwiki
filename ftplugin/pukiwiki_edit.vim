" vim: set ts=4 sts=4 sw=4 noet ai fdm=marker:
" $Id: pukiwiki_edit.vim 12 2008-07-27 10:00:03Z ishii $

scriptencoding euc-jp

nnoremap <silent> <buffer> <CR>    :call <SID>PW_move()<CR>
nnoremap <silent> <buffer> <TAB>   :call <SID>PW_bracket_move()<CR>
nnoremap <silent> <buffer> <S-TAB> :call <SID>PW_bracket_move_rev()<CR>

let s:pukivim_ro_menu = "\n[[トップ]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]\n------------------------------------------------------------------------------\n"
"let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:bracket_name = '\[\[\_.\{-}\]\]'

if !exists('*s:PW_move')"{{{
function! s:PW_move()
	if line('.') < 4
		let cur = AL_matchstr_undercursor('\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]')
	else
		let cur = AL_matchstr_undercursor(s:bracket_name)
	endif

	if cur == ''
		let line = getline('.')
		if line == '#contents'
			setlocal foldmethod=expr foldexpr=getline(v:lnum)=~'^*'?'>1':'='
			return
		endif
		return
	endif

	if &modified
		call AL_echo('変更が保存されていません。', 'ErrorMsg')
		return
	endif

	let cur = substitute(cur, '\[\[\(.*\)\]\]', '\1', '')
	if line('.') < 4
		if cur == 'トップ'
			let g:pukiwiki_current_site_top = b:top
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:top)
		endif
		if cur == 'リロード'
			let g:pukiwiki_current_site_top = b:top
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:page)
		endif
		if cur == '新規'
			let page = input('新規ページ名: ')
			if page == ''
				return
			endif
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, page)
		endif
		if cur == '一覧'
			call s:PW_show_page_list()
		endif
		if cur == '単語検索'
			call s:PW_show_search()
		endif
		if cur == '最終更新'
			call s:PW_show_recent()
		endif
		if cur == 'ヘルプ'
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, 'ヘルプ')
		endif
		return
	endif

	" InterWikiNameのエイリアスではないエイリアス
	" つまり、ただのエイリアス
	if cur =~ '>'
		let cur = substitute(cur, '^.*>\([^:]*\)$', '\1', '')
	endif

	if cur =~ ':'
		return
	endif

	echo cur
	let g:pukiwiki_current_site_name = b:site_name
	let g:pukiwiki_current_site_top = b:top
	call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, cur)
endfunction
endif"}}}

function! s:PW_bracket_move()"{{{
	let tmp = @/
	let @/ = s:bracket_name
	silent! execute "normal! n"
	execute "normal! ll"
	let @/ = tmp
endfunction"}}}

function! s:PW_bracket_move_rev()"{{{
	let tmp = @/
	let @/ = s:bracket_name
	execute "normal! hhh"
	silent! execute "normal! N"
	execute "normal! ll"
	let @/ = tmp
endfunction"}}}

if !exists('*s:PW_show_page_list')"{{{
function! s:PW_show_page_list()
	let url = b:url . '?cmd=list'
	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' ' . url
	call AL_system(cmd)

	let site_name = b:site_name
	let url       = b:url
	let enc       = b:enc
	let top       = b:top
	let page      = 'cmd=list'

	execute ":e ++enc=" . b:enc . " " . result
	execute ":set filetype=pukiwiki_edit"
	runtime! ftplugin/pukiwiki_edit.vim
	let status_line = page . ' ' . site_name
	execute ":f " . escape(status_line, ' ')
	execute "normal! 1GdG"
	let body = PW_fileread(result)
	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<a id\_.\{-}<strong>\(\_.\{-}\)<\/strong><\/a>', '\[\[\1\]\]', 'g')
	execute ":setlocal noai"
	execute "normal! i" . body
	silent! %g/^$/d
	silent! %g/<div/d
	silent! %g/<\/div/d
	silent! %g/<ul/d
	silent! %g/<\/ul/d
	silent! %g/^\s*<\/li/d
	silent! %s/^.*<li><a.*>\(.*\)<\/a><small>\(.*\)<\/small>.*$/\t\[\[\1\]\] \2/
	silent! %g/^\[/d
	silent! %s/\s*<li>\[\[\(.*\)\]\]$/\1/

	let b:site_name = site_name
	let b:url       = url
	let b:enc       = enc
	let b:top       = top
	let b:page      = 'cmd=list'

	execute ":setlocal noai"
	execute "normal! gg0i" . b:site_name . " " . b:page . s:pukivim_ro_menu

	call AL_decode_entityreference_with_range('%')
	execute ":set nomodified"
	execute ":setlocal nomodifiable"
	execute ":setlocal readonly"
	execute ":setlocal noswapfile"
endfunction
endif"}}}

if !exists('*s:PW_show_search')"{{{
function! s:PW_show_search()
	let word = input('キーワード: ')
	if word == ''
		return
	endif
	let type = 'AND'
	let andor = input('(And/or): ')
	if andor =~ '^\co'
		let type = 'OR'
	endif

	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' -d encode_hint=' . AL_urlencode('ぷ')
	let cmd = cmd . ' -d word=' . AL_urlencode(word)
	let cmd = cmd . ' -d type=' . type . ' -d cmd=search ' . b:url
	call AL_system(cmd)

	let site_name = b:site_name
	let url       = b:url
	let enc       = b:enc
	let top       = b:top
	let page      = 'cmd=search'

	execute ":e ++enc=" . b:enc . " " . result
	execute ":set filetype=pukiwiki_edit"
	runtime! ftplugin/pukiwiki_edit.vim
	let status_line = page . ' ' . site_name
	execute ":f " . escape(status_line, ' ')
	execute "normal! 1GdG"
	let body = PW_fileread(result)
	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '\(.*\)<form action.*', '\1', '')
	execute ":setlocal noai"
	execute "normal! i" . body

	silent! %g/<div/d
	silent! %g/<ul/d
	silent! %g/<\/ul/d
	silent! %s/<strong class="word.">//g
	silent! %s/<\/strong>//g
	silent! %s/<strong>//g
	silent! %s/^.*<li><a.*>\(.*\)<\/a>\(.*\)<\/li>$/\t\[\[\1\]\] \2/

	let b:site_name = site_name
	let b:url       = url
	let b:enc       = enc
	let b:top       = top
	let b:page      = 'cmd=search'

	execute "normal! GddggPi" . b:site_name . " " . b:page . s:pukivim_ro_menu

	execute ":set nomodified"
	execute ":setlocal nomodifiable"
	execute ":setlocal readonly"
	execute ":setlocal noswapfile"
endfunction
endif"}}}

if !exists('*s:PW_show_recent')"{{{
function! s:PW_show_recent()
	let url = b:url . '?RecentChanges'
	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' ' . url
	call AL_system(cmd)

	let site_name = b:site_name
	let url       = b:url
	let enc       = b:enc
	let top       = b:top
	let page      = 'RecentChanges'

	execute ":e ++enc=" . b:enc . " " . result
	execute ":set filetype=pukiwiki_edit"
	runtime! ftplugin/pukiwiki_edit.vim
	let status_line = page . ' ' . site_name
	execute ":f " . escape(status_line, ' ')
	execute "normal! 1GdG"
	let body = PW_fileread(result)
	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	execute ":setlocal noai"
	execute "normal! i" . body
	silent! %s/^.*<li>//
	silent! %g!/a href/d
	silent! %s/<a href.*>\(.*\)<\/a>.*$/\[\[\1\]\]/

	let b:site_name = site_name
	let b:url       = url
	let b:enc       = enc
	let b:top       = top
	let b:page      = 'RecentChanges'

	execute ":setlocal noai"
	execute "normal! ggi" . b:site_name . " " . b:page . s:pukivim_ro_menu
	execute ":set nomodified"
	execute ":setlocal nomodifiable"
	execute ":setlocal readonly"
	execute ":setlocal noswapfile"

endfunction
endif"}}}

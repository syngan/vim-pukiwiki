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

nnoremap <silent> <buffer> <CR>    :call <SID>PW_move()<CR>
nnoremap <silent> <buffer> <TAB>   :call <SID>PW_bracket_move()<CR>
nnoremap <silent> <buffer> <S-TAB> :call <SID>PW_bracket_move_rev()<CR>

let s:pukivim_ro_menu = "\n[[トップ]] [[添付]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]\n------------------------------------------------------------------------------\n"
"let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:bracket_name = '\[\[\_.\{-}\]\]'

if !exists('*s:PW_move')"{{{
function! s:PW_move()
	if line('.') < 4
		" ヘッダ部分
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
"			let g:pukiwiki_current_site_top = b:top
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:top)
		elseif cur == 'リロード'
"			let g:pukiwiki_current_site_top = b:top
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:page)
		elseif cur == '新規'
			let page = input('新規ページ名: ')
			if page == ''
				return
			endif
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, page)
		elseif cur == '一覧'
			call s:PW_show_page_list()
		elseif cur == '単語検索'
			call s:PW_show_search()
		elseif cur == '添付'
			call s:PW_show_attach(b:site_name, b:url, b:enc, b:top, b:page)
		elseif cur == '最終更新'
"			call s:PW_show_recent()
			let page = 'RecentChanges'
			call PW_get_source_page(b:site_name, b:url, b:enc, b:top, page)
		elseif cur == 'ヘルプ'
			call PW_get_source_page(b:site_name, b:url, b:enc, b:top, 'FormattingRules')
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
"	let g:pukiwiki_current_site_name = b:site_name
"	let g:pukiwiki_current_site_top = b:top
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


"----------------------------------------------
" 添付ファイル用の画面を表示する.
" 表示せずにコマンドだけ・・・のほうがいいのかな
"----------------------------------------------
function! s:PW_show_attach(site_name, url, enc, top, page) "{{{
	" 添付ファイルの一覧
	let enc_page = iconv(a:page, &enc, a:enc)
	let enc_page = PW_urlencode(enc_page)
	let url = a:url . '?plugin=attach&pcmd=list&refer=' . enc_page
	
	let tmp = tempname()
	let cmd = "curl -s -o " . tmp .' "'. url . '"'
	echo cmd
	let result = system(cmd)

	let body = PW_fileread(tmp)
	let body = iconv(body, a:enc, &enc)
	let body = substitute(body, '^.*\(<div id="body">.*<hr class="full_hr" />\).*$', '\1', '')
	let body = substitute(body, '^.*<div id="body">.*<ul>\(.*\)</ul>.*<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<span class="small">.\{-}</span>\n', '', 'g')
	let body = substitute(body, ' </li>\n', '', 'g')
	let body = substitute(body, ' <li><a.\{-} title="\(.\{-}\)">\(.\{-}\)</a>', '\2\t(\1)', 'g')
	" index.php?plugin=attach&pcmd=list&refer=$page

	execute "normal! ggdG"
	execute ":setlocal indentexpr="
	execute ":setlocal noautoindent"
	execute ":setlocal paste"
	execute "normal! i" . a:site_name . " " . b:page . s:pukivim_ro_menu 

	execute "normal! i添付ファイル一覧 [[" . b:page . "]]\n"
	execute "normal! i" . body
	execute "normal! gg"


	execute ":set nomodified"
	execute ":setlocal nomodifiable"
	execute ":setlocal readonly"
	execute ":setlocal noswapfile"

endfunction "}}}

if !exists('*s:PW_show_page_list')"{{{
function! s:PW_show_page_list()
	let url = b:url . '?cmd=list'
	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' "' . url . '"'
	call AL_system(cmd)

	let site_name = b:site_name
	let url       = b:url
	let enc       = b:enc
	let top       = b:top
	let page      = 'cmd=list'

	if ! filereadable(result)
		echo "cannot obtain the list: " . cmd
		return 
	endif

	execute ":e ++enc=" . b:enc . " " . result
	execute ":set filetype=pukiwiki_edit"

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.9.list-1'
		call AL_write(file)
		call AL_echo(file)
	endif


	runtime! ftplugin/pukiwiki_edit.vim
	let status_line = page . ' ' . site_name
	silent! execute ":f " . escape(status_line, ' ')
	let body = PW_fileread(result)
	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<a id\_.\{-}<strong>\(\_.\{-}\)<\/strong><\/a>', '\[\[\1\]\]', 'g')
"	let body = substitute(body, '<li><a href=".\{-}">\(\_.\{-}\)<\/a><small>(.*)</small></li>', '\[\[\1\]\]', 'g')

	execute "normal! ggdG"
	execute ":setlocal noai"
	execute ":setlocal paste"
	execute "normal! i" . body

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.9.list-2'
		call AL_write(file)
		call AL_echo(file)
	endif

	" がんばって加工
	silent! %g/^$/d
	silent! %g/<div/d
	silent! %g/<\/div/d
	silent! %g/<ul/d
	silent! %g/<\/ul/d
	silent! %g/^\s*<\/li/d
	silent! %s/^.*<li><a.*>\(.*\)<\/a><small>\(.*\)<\/small>.*$/\t\[\[\1\]\] \2/
	silent! %g/^\[/d
	silent! %g/<br \/.*/d
	silent! %s/\s*<li>\[\[\(.*\)\]\]$/\1/


	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.9.list-3'
		call AL_write(file)
		call AL_echo(file)
	endif

	let b:site_name = site_name
	let b:url       = url
	let b:enc       = enc
	let b:top       = top
	let b:page      = 'cmd=list'

	execute ":setlocal noai"
	execute "normal! gg0i" . b:site_name . " " . b:page . s:pukivim_ro_menu
	execute "normal! gg"

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
	let cmd = 'curl -s -o ' . result . ' -d encode_hint=' . PW_urlencode('ぷ')
	let cmd = cmd . ' -d word=' . PW_urlencode(word)
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
	silent! execute ":f " . escape(status_line, ' ')
	execute "normal! ggdG"
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

	" 最終行に [... 10 ページ見つかりました] メッセージ
	" それを最初にだす
	execute "normal! GddggP0i" . b:site_name . " " . b:page . s:pukivim_ro_menu

	execute "normal! gg"
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
	silent! execute ":f " . escape(status_line, ' ')
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


function! PW_fileupload() range "{{{

	let pass = input('パスワード: ')

	let enc_page = iconv(b:page, &enc, b:enc)
	let enc_page = PW_urlencode(enc_page)
	let url = b:url . '?plugin=attach&pcmd=list&refer=' . enc_page

	let tmpfile = tempname()
	let cmd = 'curl -s -o ' . tmpfile . ' -F encode_hint=' . PW_urlencode('ぷ')
	let cmd = cmd . ' -F plugin=attach'
	let cmd = cmd . ' -F pcmd=post'
	let cmd = cmd . ' -F refer=' . enc_page
	let cmd = cmd . ' -F pass=' . pass 

    for linenum in range(a:firstline, a:lastline)
        "Replace loose ampersands (as in DeAmperfy())...
        let curr_line   = getline(linenum)
		let fcmd = cmd . ' -F "attach_file=@' . curr_line . '"'
	
		let fcmd = fcmd . ' "' . b:url . '"'
		let result = system(fcmd)
		let errcode = v:shell_error 
		if errcode != 0
			let msg = ''
			if errcode == 26 
				let msg = 'file not found'
			endif

			let msg = "\tcurl error (" . errcode . ':' . msg . ')'

			call setline(linenum, curr_line . msg)
			continue
		endif

		let body = PW_fileread(tmpfile)
		let body = iconv(body, b:enc, &enc)
		let body = substitute(body, '^.*<h1 class="title">\(.*\)</h1>.*$', '\1', '')
		let body = substitute(body, '<a href=".*">\(.*\)</a>', '[[\1]]', '')
		call setline(linenum, curr_line . "\t" . body)
    endfor

endfunction "}}}



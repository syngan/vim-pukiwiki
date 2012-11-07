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

" nnoremap {{{
nnoremap <silent> <buffer> <CR>    :call <SID>PW_move()<CR>
nnoremap <silent> <buffer> <TAB>   :call <SID>PW_bracket_move()<CR>
nnoremap <silent> <buffer> <S-TAB> :call <SID>PW_bracket_move_rev()<CR>
"nnoremap <silent> <buffer> B       :call PW_get_last_page()<CR>
" }}}

if exists('s:loaded_ftplugin_pukiwiki') && s:loaded_ftplugin_pukiwiki
  finish
endif
let s:loaded_ftplugin_pukiwiki = 1

function! PW_set_loaded_flag(val) "{{{
	let s:loaded_ftplugin_pukiwiki = a:val
endfunction "}}}

" variables {{{
let s:pukivim_ro_menu = "\n"
	\ . "[[トップ]] [[添付]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]\n"
	\ . "------------------------------------------------------------------------------\n"
"let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:bracket_name = '\[\[\_.\{-}\]\]'
"}}}

"try
function! s:PW_move()  "{{{
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
			call PW_get_top_page(b:site_name)
		elseif cur == 'リロード'
			if b:page == 'FormattingRules' || b:page == 'RecentChanges'
				call PW_get_source_page(b:site_name, b:page)
			else
				call PW_get_edit_page(b:site_name, b:page, 0)
			endif
		elseif cur == '新規'
			let page = input('新規ページ名: ')
			if page == ''
				return
			endif
			call PW_get_edit_page(b:site_name, page, 1)
		elseif cur == '一覧'
			call s:PW_show_page_list()
		elseif cur == '単語検索'
			call s:PW_show_search()
		elseif cur == '添付'
			call s:PW_show_attach(b:site_name, b:page)
		elseif cur == '最終更新'
			let page = 'RecentChanges'
			call PW_get_source_page(b:site_name, page)
		elseif cur == 'ヘルプ'
			call PW_get_source_page(b:site_name, 'FormattingRules')
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

	call PW_get_edit_page(b:site_name, cur, 1)
endfunction "}}}
"catch /^Vim\%((\a\+)\)\?:E127/
"endtry

function! s:PW_bracket_move() "{{{
	let tmp = @/
	let @/ = s:bracket_name
	silent! execute "normal! n"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}

function! s:PW_bracket_move_rev() "{{{
	let tmp = @/
	let @/ = s:bracket_name
	execute "normal! hhh"
	silent! execute "normal! N"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}

"try
function! s:PW_show_attach(site_name, page) "{{{
"----------------------------------------------
" 添付ファイル用の画面を表示する.
" 表示せずにコマンドだけ・・・のほうがいいのかな
"----------------------------------------------

	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']


	" 添付ファイルの一覧
	let enc_page = iconv(a:page, &enc, enc)
	let enc_page = PW_urlencode(enc_page)
	let url = url . '?plugin=attach&pcmd=list&refer=' . enc_page
	
	let tmp = tempname()
	
	let cmd = "curl -s -o " . tmp .' "'. url . '"'
	let result = AL_system(cmd)

	let body = PW_fileread(tmp)
	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*\(<div id="body">.*<hr class="full_hr" />\).*$', '\1', '')
	let body = substitute(body, '^.*<div id="body">.*<ul>\(.*\)</ul>.*<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<span class="small">.\{-}</span>\n', '', 'g')
	let body = substitute(body, ' </li>\n', '', 'g')
	let body = substitute(body, ' <li><a.\{-} title="\(.\{-}\)">\(.\{-}\)</a>', '\2\t(\1)', 'g')

	" [添付ファイルがありません] 対応
	let body = substitute(body, '<.\{-}>', '', 'g')
	let body = substitute(body, '\n\n*', '\n', 'g')

	call PW_newpage(a:site_name, a:page)
	call PW_set_statusline(a:site_name, a:page)

	execute "normal! i" . a:site_name . " " . b:page . s:pukivim_ro_menu 
	execute "normal! i添付ファイル一覧 [[" . b:page . "]]\n"
	execute "normal! i" . body

	call PW_endpage(a:site_name, a:page, 1)
endfunction "}}}
"catch /^Vim\%((\a\+)\)\?:E127/
"endtry

"try
function! s:PW_show_page_list() "{{{

	let sitedict = g:pukiwiki_config[b:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let url = url . '?cmd=list'
	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' "' . url . '"'
	call AL_system(cmd)

	if ! filereadable(result)
		echo "cannot obtain the list: " . cmd
		return 
	endif

	call PW_newpage(b:site_name, 'cmd=list')
	call PW_set_statusline(b:site_name, b:page)

	let body = PW_fileread(result)
	call delete(result)

	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<a id\_.\{-}<strong>\(\_.\{-}\)<\/strong><\/a>', '\[\[\1\]\]', 'g')
"	let body = substitute(body, '<li><a href=".\{-}">\(\_.\{-}\)<\/a><small>(.*)</small></li>', '\[\[\1\]\]', 'g')

	execute "normal! i" . body

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.9.list-2'
		call AL_write(file)
		call AL_echo(file)
	endif

	" がんばって加工
	" @REG
	let regbak = @"
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
	let @" = regbak

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.9.list-3'
		call AL_write(file)
		call AL_echo(file)
	endif

	execute ":setlocal noai"
	execute "normal! gg0i" . b:site_name . " " . b:page . s:pukivim_ro_menu

	call AL_decode_entityreference_with_range('%')

	call PW_endpage(b:site_name, b:page, 1)
endfunction "}}}
"catch /^Vim\%((\a\+)\)\?:E127/
"endtry

"try
function! s:PW_show_search() "{{{

	let sitedict = g:pukiwiki_config[b:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

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
	let cmd = cmd . ' -d type=' . type . ' -d cmd=search ' . url
	call AL_system(cmd)

	call PW_newpage(b:site_name, 'cmd=search')
	call PW_set_statusline(b:site_name, b:page)

	let body = PW_fileread(result)
	call delete(result)

	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '\(.*\)<form action.*', '\1', '')
"	let body = substitute(body, '^<div class=[^\n]\{-}$', '', '')
	execute "normal! i" . body

	" がんばって加工
	" このへんでレジスタを壊すのが嫌い
	" @REG
	let regbak = @"
	silent! %g/<div/d
	silent! %g/<ul/d
	silent! %g/<\/ul/d
	silent! %s/<strong class="word.">//g
	silent! %s/<\/strong>//g
	silent! %s/<strong>//g
	silent! %s/^.*<li><a.*>\(.*\)<\/a>\(.*\)<\/li>$/\t\[\[\1\]\] \2/

	" 最終行に [... 10 ページ見つかりました] メッセージ
	" それを最初にだす
	" @REG
	execute "normal! GddggP0i" . b:site_name . " " . b:page . s:pukivim_ro_menu
	let @" = regbak

	call PW_endpage(b:site_name, b:page, 1)
endfunction "}}}
"catch /^Vim\%((\a\+)\)\?:E127/
"endtry

"try
function! PW_fileupload() range "{{{

	let sitedict = g:pukiwiki_config[b:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let pass = input('パスワード: ')

	let enc_page = iconv(b:page, &enc, enc)
	let enc_page = PW_urlencode(enc_page)

	let tmpfile = tempname()
	let cmd = 'curl -s -o ' . tmpfile . ' -F encode_hint=' . PW_urlencode('ぷ')
	let cmd = cmd . ' -F plugin=attach'
	let cmd = cmd . ' -F pcmd=post'
	let cmd = cmd . ' -F refer=' . enc_page
	let cmd = cmd . ' -F pass=' . pass 

    for linenum in range(a:firstline, a:lastline)
        "Replace loose ampersands (as in DeAmperfy())...
        let curr_line   = getline(linenum)

		" いくつか自分でチェックするか.
		" file が読めるか. directory でないか.
		if isdirectory(curr_line)
			let msg = "\tdirectory"
			call setline(linenum, curr_line . msg)
			continue
		endif

		if !filereadable(curr_line)
			let msg = "\tcannot read"
			call setline(linenum, curr_line . msg)
			continue
		endif

		let fcmd = cmd . ' -F "attach_file=@' . curr_line . '"'
		let fcmd = fcmd . ' "' . url . '"'
		let result = AL_system(fcmd)
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
		let body = iconv(body, enc, &enc)
		let body = substitute(body, '^.*<h1 class="title">\(.*\)</h1>.*$', '\1', '')
		let body = substitute(body, '<a href=".*">\(.*\)</a>', '[[\1]]', '')
		call setline(linenum, curr_line . "\t" . body)
    endfor

endfunction "}}}
"catch /^Vim\%((\a\+)\)\?:E127/
"endtry

" これはエラーになる
function! PW_setfiletype_ng() " {{{
	execute ":setlocal filetype=pukiwiki_edit"
endfunction "}}}

" vim:set foldmethod=marker:

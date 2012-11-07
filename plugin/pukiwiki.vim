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

" option {{{
if exists('plugin_pukiwiki_disable')
	finish
endif

scriptencoding euc-jp

"---------------------------------------------
" global 変数
"---------------------------------------------

" デバッグ用
if !exists('g:pukiwiki_debug')
	let g:pukiwiki_debug = 0
endif

" ブックマークを保存する場所
" マルチユーザ設定
if !exists('g:pukiwiki_multiuser')
	let g:pukiwiki_multiuser = has('unix') && !has('macunix') ? 1 : 0
endif

" ユーザファイルの位置設定
if !exists('g:pukiwiki_datadir')
	if g:pukiwiki_multiuser
		if has('win32')
			let g:pukiwiki_datadir = $HOME . '/vimfiles/pukiwiki'
		else
			let g:pukiwiki_datadir = $HOME . '/.vim/pukiwiki'
		endif
	else
		let g:pukiwiki_datadir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '')
	endif
endif

" タイムスタンプを変更するかどうかの確認メッセージ
" 1 = いつも yes
" 0 = いつも no
"-1 (else) 確認する
if !exists('g:pukiwiki_timestamp_update')
	let g:pukiwiki_timestamp_update = -1
endif

"}}}

command! -nargs=* PukiVim :call PukiWiki(<f-args>)

" variables {{{
let s:pukiwiki_history = []
" }}}

" vital.vim {{{
"let s:VITAL = vital#of('vim-pukiwiki')
"let s:HTTP = s:VITAL.import('Web.Http')
" }}}

function! PW_newpage(site_name, page) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let enc = sitedict['encode']

	execute ":e! ++enc=" . enc . " " . tempname()
	execute ":setlocal modifiable"
	execute ":setlocal indentexpr="
	execute ":setlocal noautoindent"
	execute ":setlocal paste"
	execute ':setlocal nobuflisted'

	execute ":setlocal filetype=pukiwiki_edit"

	let b:site_name = a:site_name
	let b:page      = a:page
endfunction "}}}

function! PW_endpage(site_name, page, readonly) "{{{
	execute "normal! gg"
	execute ':setlocal nobuflisted'
	execute ":set nomodified"
	if a:readonly
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
	endif
	execute ":setlocal noswapfile"
	silent! execute ":redraws!"
endfunction "}}}

function! PW_set_statusline(site_name, page) "{{{
"	let status_line = a:page . ' ' . a:site_name
	let status_line = a:page
	let status_line = escape(status_line, ' ')
	silent! execute ":f " . status_line
	return status_line
endfunction "}}}

function! PW_buf_vars() "{{{
	" デバッグ用
	call AL_echokv('site_name' , b:site_name)
	call AL_echokv('page'      , b:page)
	call AL_echokv('digest'    , b:digest)
	call AL_echokv('original'  , b:original)

	let sitedict = g:pukiwiki_config[a:site_name]
	call AL_echokv('url' , sitedict['url'])
	call AL_echokv('top' , sitedict['top'])
	call AL_echokv('enc' , sitedict['encode'])


endfunction "}}}

function! s:PW_get_digest(str) "{{{
	" [[編集]] 画面から digest を取得する
	let s = matchstr(a:str,
	\     '<input type="hidden" name="digest" value="\zs.\{-}\ze" />')
	return s
endfunction "}}}

function! PukiWiki(...) "{{{
	if !s:PW_init_check()
		echohl ErrorMsg 
		echo '起動に失敗しました。'
		echohl None
		return
	endif

	if !call("s:PW_read_pukiwiki_list", a:000)
"		AL_echo('ブックマークの読み込みに失敗しました。', 'ErrorMsg')
		return
	endif

endfunction "}}}

function! s:PW_read_pukiwiki_list(...) "{{{
" bookmark
" PukiVim [ SiteName [ PageName ]]
"
	if !exists('g:pukiwiki_config')
		AL_echo('g:pukiwiki_config does not defined.', 'ErrorMsg')
		return 0
	endif

	if a:0 == 0
		" 問い合わせ
		let site_name = input('サイト名: ')
	else
		let site_name = a:1
	endif

	try 
		if !has_key(g:pukiwiki_config, site_name)
			call AL_echo('site "' . site_name . '" not found.', 'ErrorMsg')
			return 0
		endif
	catch /^Vim\%((\a\+)\)\?:E715/
		call AL_echo('g:pukiwiki_config is not a dictionary.', 'ErrorMsg')
		return 0
	endtry
	
	let dict = g:pukiwiki_config[site_name]
	if (!has_key(dict, 'url'))
		call AL_echo('"url" does not defined.', 'ErrorMsg')
		return 0
	endif
	let url = dict['url']

	if (!has_key(dict, 'encode'))
		let dict['encode'] = 'euc-jp'
	endif
	if (has_key(dict, 'top'))
		let top = dict['top']
	else
		let top	= 'FrontPage'
		let dict['top'] = top
	endif

	if a:0 > 1
		let page  = a:2
	else
		let page  = top
	endif

	" 最初に一度だけ空ファイルを開く
	if page == 'RecentChanges'
		call PW_get_source_page(site_name, page)
	else
		call PW_get_edit_page(site_name, page, 1)
	endif
	return 1

endfunction "}}}

function! s:PW_init_check() "{{{
	" alice.vimのロードを確実にする
	if !exists('*AL_version')
		runtime! plugin/alice.vim
	endif

	" alice.vim の有無をチェック
	if !exists('*AL_version')
		echohl ErrorMsg
		echo 'alice.vim がロードされていません。'
		echohl None
		return 0
	endif

	" curl の有無をチェック
	let curl = 'curl'
	if has('win32')
		let curl = 'curl.exe'
	endif
	if curl != AL_hascmd('curl')
		call AL_echo('curl が見つかりません。', 'ErrorMsg')
		return 0
	endif

"	if !AL_mkdir(g:pukiwiki_datadir)
"		AL_echo('データディレクトリーが作成できません。', 'ErrorMsg')
"		return 0
"	endif

	" BookMark 最初は無いからスクリプトに付属の物をユーザー用にコピーする。
"	let s:pukiwiki_list = g:pukiwiki_datadir . '/pukiwiki.list'
"	let pukivim_dir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '')
"	let s:pukiwiki_list_dist = pukivim_dir . '/pukiwiki.list-dist'
"	if !filereadable(s:pukiwiki_list)
"		if !AL_filecopy(s:pukiwiki_list_dist, s:pukiwiki_list)
"			call AL_echo('pukiwiki.list-dist のコピーに失敗しました。', 'ErrorMsg')
"			return 0
"		endif
"	endif

	return 1
endfunction "}}}


function! PW_get_top_page(site_name) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let top = sitedict['top']

	return PW_get_edit_page(a:site_name, top, 1)

endfunction "}}}

function! PW_get_edit_page(site_name, page, opennew) "{{{
" edit ページを開く
	return s:PW_get_page(a:site_name, a:page, "edit", a:opennew)
endfunction "}}}

function! PW_get_source_page(site_name, page) "{{{
	return s:PW_get_page(a:site_name, a:page, "source", 1)
endfunction "}}}

function! s:PW_get_page(site_name, page, pwcmd, opennew) "{{{
" ページを開く
" pwcmd = "edit" or "source"
	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']
	let start = localtime()
	let enc_page = iconv(a:page, &enc, enc)
	let enc_page = PW_urlencode(enc_page)
"	let enc_page = s:HTTP.escape(enc_page)
	" 勝手に utf-8 に変換しよるからつかえない.
	let cmd = url . "?cmd=" . a:pwcmd . "&page=" . enc_page
	let tmp = tempname()
	if 1
		let cmd = "curl -s -o " . tmp .' '. AL_quote(cmd)
		let ret = AL_system(cmd)
		let result = PW_fileread(tmp)
		call delete(tmp)
	else
"		let result = s:HTTP.get(cmd)
	endif

	let result = iconv(result, enc, &enc)

	if a:pwcmd == 'edit' 
		if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
"			call AL_echo('ページの読み込みに失敗しました。凍結されているか、認証が必要です。', 'WarningMsg')
			return PW_get_source_page(a:site_name, a:page)
		endif
	elseif a:pwcmd == 'source'
		if result !~ '<pre id="source">'
			call AL_echo('ページの読み込みに失敗しました。認証が必要です。', 'WarningMsg')
			return
		endif

	else
		call AL_echo('unknown command: ' . a:pwcmd, 'WarningMsg')
		return
	endif

	let phase1 = localtime()

	if a:pwcmd == 'edit' 
		let digest = s:PW_get_digest(result)
		let msg = matchstr(result, '.*<textarea\_.\{-}>\zs\_.\{-}\ze</textarea>.*')
	else
		" cmd='source'
		let digest = ''
		let msg = matchstr(result, '.*<pre id="source">\zs\_.\{-}\ze</pre>.*')
	endif

	let phase2 = localtime()

	" 全消去
	if a:opennew
		call PW_newpage(a:site_name, a:page)
	else
		" @REG
		let regbak = @"
		execute 'normal! ggdG'
		let @" = regbak
	endif

	silent! execute "normal! i" . a:site_name . " " . a:page . "\n"
				\ . "[[トップ]] [[添付]] [[リロード]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]\n"
				\ . "------------------------------------------------------------------------------\n"

"	silent! execute "normal! ihistory>>>>>" . len(s:pukiwiki_history) . "\n" 
"	for elm in s:pukiwiki_history
"		silent! execute "normal! i" . elm[4] . "\n"
"	endfor
"	silent! execute "normal! ihistory<<<<<" . len(s:pukiwiki_history) . "\n" 
	silent! execute "normal! i" . msg

	call AL_decode_entityreference_with_range('%')
	let phase3 = localtime()

	let b:digest    = digest
	let b:original  = msg

	let status_line = PW_set_statusline(b:site_name, b:page)
	if a:pwcmd == 'edit'
		augroup PukiWikiEdit
			execute "autocmd! BufWriteCmd " . status_line . " call s:PW_write()"
		augroup END
		call PW_endpage(a:site_name, a:page, 0)
	endif
	if a:pwcmd == 'source'
		call PW_endpage(a:site_name, a:page, 1)
	endif

	if len(s:pukiwiki_history) == 0 || s:pukiwiki_history[-1] != [a:site_name, a:page, a:pwcmd]
		call add(s:pukiwiki_history, [a:site_name, a:page, a:pwcmd])
	endif

	if g:pukiwiki_debug
		let phase4 = localtime()
		echo 'start - phase1  = ' . (phase1 - start)
		echo 'phase1 - phase2 = ' . (phase2 - phase1)
		echo 'phase2 - phase3 = ' . (phase3 - phase2)
		echo 'phase3 - phase4 = ' . (phase4 - phase3)
	endif

endfunction "}}}

function! PW_get_back_page() "{{{
	if (len(s:pukiwiki_history) > 0) 
		let last = remove(s:pukiwiki_history, -1)
		if last[1] == b:page && len(s:pukiwiki_history) > 0
			let last = remove(s:pukiwiki_history, -1)
		else
			return 
		endif
		call s:PW_get_page(last[0], last[1], last[2], 1) 
	endif
endfunction "}}}

function! s:PW_write() "{{{

	if ! &modified
		return
	endif

	let sitedict = g:pukiwiki_config[b:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let notimestamp = ''
	let lineno = line('.')

	if g:pukiwiki_timestamp_update == 1
	  let notimestamp = ''
	elseif g:pukiwiki_timestamp_update == 0
		let notimestamp = 'true'
	else
		let last_confirm = input('タイムスタンプを変更しない。(y/N): ')
		if last_confirm =~ '^\cy'
			let notimestamp = 'true'
		endif
	endif

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.1'
		call AL_write(file)
		call AL_echo(file)
	endif

	" ヘッダの削除. ユーザがヘッダを修正すると
	" 書き込みが壊れるだめな仕様
	" @REG
	let regbak = @"
	silent! execute "normal! gg3D"
	let @" = regbak
	let cl = 1
	execute ":setlocal fenc="
	while cl <= line('$')
		let line = getline(cl)
		let line = iconv(line, &enc, enc)
		let line = PW_urlencode(line)
		call setline(cl, line)
		let cl = cl + 1
	endwhile

	if 1 < line('$')
		silent! %s/$/%0A/
		execute ":noh"
		let @/ = ''
	endif

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.2'
		call AL_write(file)
		call AL_echo(file)
	endif


	execute ":setlocal noai"
	let cmd = "normal! 1G0iencode_hint=" . PW_urlencode( iconv( 'ぷ', &enc, enc ) )
	let cmd = cmd . "&cmd=edit&page=" . PW_urlencode( iconv( b:page, &enc, enc ) )
	let cmd = cmd . "&digest=" . b:digest . "&write=" . PW_urlencode( iconv( 'ページの更新', &enc, enc ) )
	let cmd = cmd . "&notimestamp=" . notimestamp
	let cmd = cmd . "&original="
	let cmd = cmd . "&msg="
	call AL_execute(cmd)

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.3'
		call AL_write(file)
		call AL_echo(file)
	endif

	let post = tempname()
	call AL_write(post)
	let result = tempname()
	let cmd = "curl -s -o " . result . " -d @" . post . ' "' . url . '"'
	call AL_system(cmd)

	if ! g:pukiwiki_debug
		call delete(post)
	elseif ! filereadable(result)
		call delete(post)
	endif

	" 成功するとPukiWikiがlocationヘッダーを吐くのでresultが作成されない。
	" 作成されている場合には何らかのエラーをHTMLで吐き出している。
	if filereadable(result)
		let body = PW_fileread(result)
		let body = iconv( body, enc, &enc )
		if body =~ '<title>\_.\{-}を削除しました\_.\{-}<\/title>'
			let page = b:page
			call PW_get_edit_page(b:site_name, top, 0)
			call AL_echo(page . ' を削除しました')
			return
		endif

		" 失敗
		execute ":undo"
		execute ":set nomodified"
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
		let site_name = b:site_name
		let page      = b:page

		" 書き込みしようとしたバッファの名前の前に'ローカル'を付けて
		" 現在のサーバー上の内容を取得して'diffthis'を実行する。
		call PW_set_statusline(b:site_name, 'ローカル ' . b:page)
		execute ":diffthis"
		execute ":new"

		call PW_get_edit_page(site_name, page, 0)
		execute ":diffthis"
		if g:pukiwiki_debug
			echo "digest=[" . b:digest . "] cmd=[" . cmd . "]"
			echo "&enc=" . &enc . ", enc=" . enc . ", page=" . b:page
			echo "iconv=" . Byte2hex(iconv(b:page, &enc, enc))
			echo "urlen=" . PW_urlencode( iconv( b:page, &enc, enc ) )
			call AL_echo('更新の衝突が発生したか、その他のエラーで書き込めませんでした。' . result, 'ErrorMsg')
		else
			call AL_echo('更新の衝突が発生したか、その他のエラーで書き込めませんでした。', 'ErrorMsg')
			call delete(result)
		endif
		return 0
	endif

	call PW_get_edit_page(b:site_name, b:page, 0)

	" 元いた行に移動
	execute "normal! " . lineno . "G"
"	silent! echo 'update ' . b:page
	if g:pukiwiki_debug
		" 毎回うっとーしいので debug 用に
		call AL_echo('更新成功！')
	endif


endfunction "}}}

function! PW_fileread(filename) "{{{
	if has('win32')
		let filename=substitute(a:filename,"/","\\","g")
	else
		let filename=a:filename
	endif
	return AL_fileread(filename)
endfunction "}}}

function! AL_filecopy(from, to) "{{{
	if isdirectory(a:from) || !filereadable(a:from)
		return 0
	endif

	if isdirectory(a:to)
		let to = a:to . '/' . AL_filename(a:from)
	else
		let to = a:to
	endif

	if has('win32') && &shell =~ '\ccmd'
		let cmd = 'copy'
	else
		let cmd = 'cp'
	endif

	let cmd = cmd . ' ' . AL_quote(a:from) . ' ' . AL_quote(to)
	if has('win32') && &shell =~ '\ccmd'
		let cmd = substitute(cmd, '\/', '\\', 'g')
	endif
	call AL_system(cmd)

	if g:pukiwiki_debug
		call AL_echo(cmd)
	endif

	if !filereadable(to)
		return 0
	endif

	return 1
endfunction "}}}

function! PW_urlencode(str) "{{{
" 1) [._-] はそのまま
" 2) [A-Za-z0-9] もそのまま。
" 3) 0x20[ ] ==> 0x2B[+]
"    以上の3つの規則に当てはまらない文字は、 全て、 "%16進数表記"に変換する。
  " Return URL encoded string

  let result = ''
  let i = 0
  while i < strlen(a:str)
    let ch = a:str[i]
    let i = i + 1
    if ch =~ '[-_.0-9A-Za-z]' 
      let result = result . ch
    elseif ch == ' '
      let result = result . '+'
    else
      let hex = AL_nr2hex(char2nr(ch))
      let result = result.'%'.(strlen(hex) < 2 ? '0' : '').hex
    endif
  endwhile
  return result
endfunction "}}}

" これはエラーにならない
function! PW_setfiletype_ok() " {{{
	execute ":setlocal filetype=pukiwiki_edit"
endfunction "}}}

" vim:set foldmethod=marker:

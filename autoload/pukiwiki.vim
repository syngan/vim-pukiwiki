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

" option {{{

scriptencoding utf-8

"}}}

" variables {{{
let s:pukiwiki_history = []

let s:pukiwiki_header_row = 4
"lockvar s:pukiwiki_header_row

"let s:pukiwiki_bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:pukiwiki_bracket_name = '\[\[\_.\{-}\]\]'
"エイリアス名の中には、全角文字を含めることができます。
"エイリアス名の中には、半角空白文字を含めることができます。
let s:regexp_alias = '[^\t<>\[\]#&":]\+'
"    ページ名に# & < > "(半角)のいずれかの文字を含む
"    ページ名の途中に:(半角)を含む(ページ名の前後はOK)
"    ページ名が/ ./ ../(半角)で始まる
"    ページ名が/(半角)で終わる
let s:regexp_page = '\(\.\{,2}/\)\@<![^\t\[\]<>#&":]\+\(/\)\@!'
" アンカー名は、半角アルファベットから始まる
" 半角アルファベット・数字・ハイフン・アンダースコアからなる文字列を指定します。
let s:regexp_anchor = '#\a[A-Za-z0-9_-]*'
let s:pukiwiki_bracket_name = '\m\[\[\(' . s:regexp_alias . '>\)\=' . s:regexp_page . '\(' . s:regexp_anchor . '\)\=\]\]'

"  \=   0 or 1
"  \+   1 or more
"http://vim-users.jp/2009/09/hack75/
"  \@!  nothing, requires NO match
"  \@<! nothing, requires NO match behind /zero-width
"
unlet s:regexp_alias
unlet s:regexp_page
unlet s:regexp_anchor
"lockvar s:pukiwiki_bracket_name

let s:pukiwiki_jumpdicts = []

" }}}

" vital.vim {{{
let s:VITAL = vital#of('vim-pukiwiki')
let s:HTML = s:VITAL.import('Web.Html')
let s:HTTP = s:VITAL.import('Web.Http')
let s:LIST = s:VITAL.import('Data.List')
" }}}

" debug {{{
function! pukiwiki#buf_vars() "{{{
	" デバッグ用
	if exists('b:pukiwiki_info')
		for key in keys(b:pukiwiki_info)
			call s:PW_echokv(key , b:pukiwiki_info[key])
		endfor
		let sitedict = g:pukiwiki_config[b:pukiwiki_info["site"]]
		for key in keys(sitedict)
			call s:PW_echokv(key , sitedict[key])
		endfor
	endif
	call s:PW_echokv('debug', g:pukiwiki_debug)
endfunction "}}}
"}}}

function! pukiwiki#version() "{{{
  return str2nr(printf('%02d%02d', 0, 26))
endfunction"}}}

function! pukiwiki#PukiWiki(...) "{{{
	if !s:PW_env_check()
		return
	endif

	if !call("s:PW_read_pukiwiki_list", a:000)
		" s:VITAL.print_error('ブックマークの読み込みに失敗しました。')
		return
	endif
endfunction "}}}

function! pukiwiki#site_comletion(arglead, cmdline, cursorpos) "{{{
	echo keys(g:pukiwiki_config)
	echo a:arglead
	echo a:cmdline
	echo a:cursorpos
	return keys(g:pukiwiki_config)
endfunction "}}}

function! s:PW_read_pukiwiki_list(...) "{{{
" bookmark
" PukiVim [ SiteName [ PageName ]]
"
	if &modified
		" @TODO 複数の同じ window を開いているときは skip したい.
		" autocmd BufWriteCmd を使っている限り無理なのか?
		call s:VITAL.print_error('変更が保存されていません。')
		return 0
	endif

	if !exists('g:pukiwiki_config')
		call s:VITAL.print_error('g:pukiwiki_config is not defined.')
		return 0
	endif

	if !s:VITAL.is_dict(g:pukiwiki_config)
		call s:VITAL.print_error('g:pukiwiki_config is not a dictionary.')
		return 0
	endif

	if a:0 == 0
		" 問い合わせ
		let site_name = input('site name: ', '', 'customlist,pukiwiki#site_comletion')
	else
		let site_name = a:1
	endif

	let msg = s:PW_valid_config(site_name)
	if msg != ''
		call s:VITAL.print_error(msg)
		return 0
	endif

	let dict = g:pukiwiki_config[site_name]

	let top = get(dict, 'top', 'FrontPage')
	let page = (a:0 > 1) ? a:2 : top

	" 最初に一度だけ空ファイルを開く
	if page == 'RecentChanges'
		call s:PW_get_source_page(site_name, page)
	else
		call s:PW_get_edit_page(site_name, page, 1)
	endif
	return 1

endfunction "}}}

function! s:PW_env_check() "{{{

	" curl/wget の有無をチェック
	if !executable('curl') && !executable('wget')
		call s:VITAL.print_error('cURL and wget are not found.')
		return 0
	endif

	return 1
endfunction "}}}

function! s:PW_valid_config(site_name) "{{{
	" g:pukiwiki_config の正当性チェック
	if !exists('g:pukiwiki_config')
		return 'g:pukiwiki_config is not defined.'
	endif
	if !s:VITAL.is_dict(g:pukiwiki_config)
		return 'g:pukiwiki_config is not a dictionary.'
	endif
	if a:site_name == ''
		return ('site name is not defined.')
	endif
	if !has_key(g:pukiwiki_config, a:site_name)
		return ('site "' . a:site_name . '" is not defined.')
	endif

	let sitedict = g:pukiwiki_config[a:site_name]
	if !s:VITAL.is_dict(sitedict)
		return 'g:pukiwiki_config.' . a:site_name . ' is not a dictionary.'
	endif

	if !has_key(sitedict, 'url')
		return 'g:pukiwiki_config.' . a:site_name . '.url is not defined.'
	endif

	return ""

endfunction "}}}

function! s:PW_is_init() " {{{
	return exists('b:pukiwiki_info') &&
		\ s:VITAL.is_dict(b:pukiwiki_info) &&
		\ has_key(b:pukiwiki_info, 'site')
endfunction "}}}

function! s:PW_gen_multipart(settings, param) " {{{
	" multipart-form を生成する
	" param.attach_file は添付するファイル名として扱う
	" それ以外は通常の POST data として扱う
	if !s:VITAL.is_dict(a:param)
		throw "invalid argument"
	endif

	" @TODO 本当はファイル内に同じ文字列がないこと、を確認する必要があるが...
	let b = "---------------------11285676"
	if has('reltime')
		let b .= substitute(reltimestr(reltime()), "\\X", '', 'g')
	else
"		let b .= substitute(tempname().localtime(), "[^A-Za-z0-9]", '', 'g')
		let b .= substitute(localtime(), "[^[:alnum:]]", '', 'g')
	endif
	let a:settings.contentType = "multipart/form-data; boundary=" . b
	let ret = []
	let CRLF = "\r"
	let b = "--" . b
	for key in keys(a:param)
		call add(ret, b . CRLF)
		if key == "attach_file"
			call add(ret, 'Content-Disposition: form-data; name="attach_file"; filename="' . a:param[key] . '"' . CRLF)
			call add(ret, 'Content-Type: application/octet-stream' . CRLF)
			call add(ret, CRLF)

			" ここでバイナリファイルが壊れる.
			let attach_body = readfile(a:param[key], 'b')
			let attach_body[-1] = attach_body[-1] . CRLF
			let ret = s:LIST.concat([ret, attach_body])
"			let ret .= 'Content-Length: ' . len(buf) . CRLF
		else
			call add(ret,'Content-Disposition: form-data; name="' . key . '"' . CRLF)
			call add(ret, CRLF)
			call add(ret, a:param[key] . CRLF)
		endif
	endfor

	call add(ret, b . '--' . CRLF)
	return ret
endfunction " }}}

function! s:PW_get_encode(str) " {{{
	" @param str join された文字列
	" pukiwiki が対象なので必ず入っていると仮定して良いはず.
	let meta = matchstr(a:str, "<meta http-equiv[^>]*charset=[^>]*\" />")
	let meta = substitute(meta, '.*charset=\(.*\). />', '\1', "")
	return meta
endfunction " }}}

function! s:PW_request(funcname, param, info, method, defset) " {{{
" Web サーバにリクエストを送り、結果を受け取る.
" @return success をキーに持つ辞書

	let site = a:info["site"]
	let page = get(a:info, 'page', '')
	let sitedict = g:pukiwiki_config[site]
	let url = sitedict['url']

	let settings = a:defset
"	let settings['client'] = 'wget'
"	let settings['client'] = ['curl', 'wget']
	let settings['url'] = url
	let settings['method'] = a:method
	" if_python は maxRedirect に対応していないため使えない
	let settings['maxRedirect'] = 0
"	let a:param['page'] = s:PW_urlencode(enc_page)
	if page != '' && !has_key(a:param, "refer")
		let a:param['page'] = page
	endif
"
	" ぷ
	"   EUC  a4d7
	"   SJIS 82d5
	"   utf8 e381b7
	"   jis  1b244224571b2842
	" @JPMES
	let a:param["encode_hint"] = "ぷ"
	if a:method == 'POST'
		let settings['data'] = a:param
		if g:pukiwiki_debug >= 5
			echo a:param
		endif
	elseif a:method == 'GET'
		let settings['param'] = a:param
		if g:pukiwiki_debug >= 5
			echo a:param
		endif
	elseif a:method == 'MULT'
		" multipart/form-data
		let settings['data'] = s:PW_gen_multipart(settings, a:param)
		let settings['method'] = 'POST'
	else
		throw 'invalid argument: method: ' . a:method
	endif
	try
		let retdic = s:HTTP.request(settings)
	catch
		call s:VITAL.print_error(a:funcname . '(1) failed: ' . v:exception)
		return {'success' : 0}
	endtry
	if !has_key(retdic, 'success')
		call s:VITAL.print_error(a:funcname . '(2) failed: ')
		return {'success' : 0}
	endif
	if !retdic['success']
		if retdic['status'] == 302
			" 書き込み時(PW_write())に成功扱いにする.
			let retdic['success'] = 1
		else
			call s:VITAL.print_error(a:funcname . '(3) failed: status=' . retdic['status'] . ' statusText="' . retdic['statusText'] . '"')
			return retdic
		endif
	endif

	let enc = s:PW_get_encode(retdic['content'])
	let retdic['content'] = s:PW_iconv_s(retdic['content'], enc)
	let retdic['enc'] = enc

	return retdic
endfunction "}}}

function! s:PW_newpage(site_name, page, pagetype) "{{{

	silent execute ":e " . tempname()
	execute ":setlocal modifiable"
	execute ":setlocal filetype=pukiwiki"

	" nnoremap {{{
	if !g:pukiwiki_no_default_key_mappings
		nnoremap <silent> <buffer> <CR>    :call pukiwiki#jump()<CR>
		nnoremap <silent> <buffer> <Tab>   :call pukiwiki#move_next_bracket()<CR>
		nnoremap <silent> <buffer> <S-Tab> :call pukiwiki#move_prev_bracket()<CR>
	"	nnoremap <silent> <buffer> B       :call pukiwiki#get_last_page()<CR>
	endif
	" }}}

	let b:pukiwiki_info = {
		\ "site" : a:site_name,
		\ "page" : a:page,
		\ "type" : a:pagetype,
		\ "header" : g:pukiwiki_show_header,
		\}
endfunction "}}}

function! s:PW_endpage(site_name, page, readonly) "{{{
	call setpos(".", [0, 1, 1, 0])
	execute ':setlocal nobuflisted'
	execute ":set nomodified"
	if a:readonly
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
	endif
	execute ":setlocal noswapfile"
	silent! execute ":redraws!"
endfunction "}}}

function! s:PW_set_statusline(site_name, page) "{{{
	let status_line = a:page . ' ' . a:site_name . '.pukiwiki'
	let status_line = escape(status_line, ' ')
	silent! execute ":f " . status_line
	return status_line
endfunction "}}}

function! pukiwiki#update_digest() "{{{
	if !s:PW_is_init()
		throw "pukiwiki.vim is not executed."
	endif

	let param = {}
	let param['cmd'] = "edit"
	let retdic = s:PW_request('update_digest', param, b:pukiwiki_info, 'GET', {})
	if !retdic['success']
		return 0
	endif
	let result = retdic['content']
	if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
		return 0
	endif

	let b:pukiwiki_info.digest = s:PW_get_digest(result)
	return 1
endfunction "}}}

function! s:PW_get_digest(str) "{{{
	" [[編集]] 画面から digest を取得する
	return matchstr(a:str,
	\     '<input type="hidden" name="digest" value="\zs.\{-}\ze" />')
endfunction "}}}

function! s:PW_get_edit_page(site_name, page, opennew) "{{{
" edit ページを開く
	return s:PW_get_page(a:site_name, a:page, "edit", a:opennew)
endfunction "}}}

function! s:PW_get_source_page(site_name, page) "{{{
	return s:PW_get_page(a:site_name, a:page, "source", 1)
endfunction "}}}

function! s:PW_insert_header(site_name, page) " {{{
	if g:pukiwiki_show_header
		call setline(1, a:site_name . " " . a:page)
		call setline(2, "[[トップ]] [[添付]] [[リロード]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]")
		call setline(3, "---------------------------------------------------------------------------------------")
		return s:pukiwiki_header_row
	else
		return 1
	endif
endfunction " }}}

function! s:PW_get_page(site_name, page, pwcmd, opennew) "{{{
" ページを開く
" pwcmd = "edit" or "source"

	let param = {}
	let param['cmd'] = a:pwcmd
	let info = {
		\ "site" : a:site_name,
		\ "page" : a:page,
	\}
	let retdic = s:PW_request('get_page', param, info, 'GET', {})
	if !retdic['success']
		return 0
	endif
	let result = retdic['content']

	if a:pwcmd == 'edit'
		if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
			" cmd=source で読み直し
			return s:PW_get_source_page(a:site_name, a:page)
		endif
	elseif a:pwcmd == 'source'
		if result !~ '<pre id="source">'
			call s:VITAL.print_error('reading the page failed. 認証が必要です。')
			return
		endif
	else
		call s:VITAL.print_error('unknown command: ' . a:pwcmd)
		return
	endif

	if a:pwcmd == 'edit'
		let digest = s:PW_get_digest(result)
		let msg = matchstr(result, '.*<textarea\_.\{-}>\zs\_.\{-}\ze</textarea>.*')
	else
		" cmd='source'
		let digest = ''
		let msg = matchstr(result, '.*<pre id="source">\zs\_.\{-}\ze</pre>.*')
	endif

	" 全消去
	if a:opennew
		call s:PW_newpage(a:site_name, a:page, "normal")
	else
		" @REG
		let regbak = @"
		execute "%d"
		let @" = regbak
		unlet regbak
	endif

	let bodyl = split(msg, "\n", 1)
	let bodyl = map(bodyl, 's:HTML.decodeEntityReference(v:val)')
	let h = s:PW_insert_header(a:site_name, a:page)
	call map(bodyl, 'setline(v:key + h, v:val)')

	let b:pukiwiki_info.digest = digest
	let b:pukiwiki_info.page = a:page
	let b:pukiwiki_info.enc = retdic['enc']

	call s:PW_set_statusline(a:site_name, a:page)

	" undo 履歴を消去する
	call s:clear_undo()

	if a:pwcmd == 'edit'
		augroup PukiWikiEdit
			execute "autocmd!"
			execute "autocmd BufWriteCmd *.pukiwiki call s:PW_write()"
		augroup END
		call s:PW_endpage(a:site_name, a:page, 0)
	endif

	if a:pwcmd == 'source'
		call s:PW_endpage(a:site_name, a:page, 1)
	endif

	if len(s:pukiwiki_history) == 0 || s:pukiwiki_history[-1] != [a:site_name, a:page, a:pwcmd]
		call add(s:pukiwiki_history, [a:site_name, a:page, a:pwcmd])
	endif

endfunction "}}}

function! s:PW_write() "{{{

	if ! &modified
		return
	endif

	let site = b:pukiwiki_info["site"]
	let page = b:pukiwiki_info["page"]

	let save_cursol = getpos(".")

	if g:pukiwiki_timestamp_update == 1
	  let notimestamp = ''
	elseif g:pukiwiki_timestamp_update == 0
		let notimestamp = 'true'
	else
		let last_confirm = s:PW_yesno('update timestamp?: ', 'y')
		let notimestamp = last_confirm ? '' : 'true'
		unlet last_confirm
	endif

	" ヘッダの削除. ユーザがヘッダを修正すると
	" 書き込みが壊れるだめな仕様
	" @REG
	if b:pukiwiki_info["header"]
"		let regbak = @"
"		silent! execute "normal! gg" . s:pukiwiki_header_row . "D"
"		let @" = regbak
		let body = getline(s:pukiwiki_header_row, line('$'))
	else
		let body = getline(1, line('$'))
	endif


	" urlencode した本文前にその他の情報設定
	let param = {}
	let param['cmd'] = 'edit'
	let param['page'] = page
	let param['digest'] = b:pukiwiki_info["digest"]
	" ページの更新'
	" @JPMES
	let param['write'] = 'ページの更新'
	let param["notimestamp"] = notimestamp
	let param["original"] = ''
	let param["msg"] = join(body, "\n")

	let retdic = s:PW_request('write', param, b:pukiwiki_info, 'POST', {})
	if !retdic['success']
		return 0
	endif

	if g:pukiwiki_debug >= 3
		echo param
		echo retdic
	endif

	" 書き込みが成功すると PukiWiki が
	" locationヘッダーを吐く & 302 を返す
	if retdic['status'] == 302

		" 再読み込み
		call s:PW_get_edit_page(site, page, 0)

		" 元いた行に移動
		call setpos('.', save_cursol)

		echo 'update ' . page . ' @ ' . site
		return 0
	endif

	" pukiwiki 上で何かのイベントが起こった.
	"  - ページの削除
	"  - 更新の衝突
	let bodyr = retdic['content']

	" @TODO もう少しまともな判定方法はないのか?
	" を削除しました
	"
	" @JPMES
	if bodyr =~ '<title>\_.\{-}を削除しました\_.\{-}<\/title>'
		execute ":set nomodified"
		call s:PW_get_top_page(site)
		echo page . ' has been deleted.'
		return
	endif

	if g:pukiwiki_debug > 0 && g:pukiwiki_debug < 3
		echo param
		echo retdic
	endif

	" @JPMES
	call s:VITAL.print_error('更新の衝突が発生したか、その他のエラーで書き込めませんでした。')
	return 0
"
"	" 失敗
"	execute ":undo"
"	execute ":set nomodified"
"	execute ":setlocal nomodifiable"
"	execute ":setlocal readonly"
"	let site_name = b:pukiwiki_site_name
"	let page      = b:pukiwiki_page
"
"	" 書き込みしようとしたバッファの名前の前に'ローカル'を付けて
"	" 現在のサーバー上の内容を取得して'diffthis'を実行する。
"	call s:PW_set_statusline(b:pukiwiki_site_name, 'ローカル ' . b:pukiwiki_page)
"	execute ":diffthis"
"	execute ":new"
"
"	call s:PW_get_edit_page(site_name, page, 0)
"	execute ":diffthis"
"	if g:pukiwiki_debug
"		echo "digest=[" . b:pukiwiki_digest . "] cmd=[" . cmd . "]"
"		echo "&enc=" . &enc . ", enc=" . enc . ", page=" . b:pukiwiki_page
"		echo "s:VITAL.iconv=" . Byte2hex(s:VITAL.iconv(b:pukiwiki_page, &enc, enc))
"		echo "urlen=" . s:PW_urlencode(s:VITAL.iconv( b:pukiwiki_page, &enc, enc))
"	endif
endfunction "}}}

function! s:PW_yesno(mes, def) " {{{

	if a:def =~? '^y'
		let m = 'Y/n'
		let def = 'y'
	elseif a:def =~ '^n'
		let m = 'y/N'
		let def = 'n'
	else
		let m = 'y/n'
		let def = ''
	endif

	let message = a:mes. ' [' . m . ']: '
	let yesno = input(message)
	while yesno !~? '^\%(y\%[es]\|n\%[o]\)$'
		redraw
		if yesno == '' && def != ''
			let yesno = def
			break
		endif
	    " Retry.
		call s:VITAL.print_error('Invalid input.')
		let yesno = input(message)
	endwhile

	return yesno =~? 'y\%[es]'
endfunction " }}}

function! pukiwiki#get_back_page() "{{{
	if (len(s:pukiwiki_history) > 0)
		let [site_name, page, pwcmd] = remove(s:pukiwiki_history, -1)
		if page == b:pukiwiki_info["page"] && len(s:pukiwiki_history) > 0
			let [site_name, page, pwcmd] = remove(s:pukiwiki_history, -1)
		else
			return
		endif
		call s:PW_get_page(site_name, page, pwcmd, 1)
	endif
endfunction "}}}

function! pukiwiki#get_history_list() "{{{
	" protected でないと困るのだが.
	return s:pukiwiki_history
endfunction "}}}

" attach files {{{
function! pukiwiki#info_attach_file(site_name, page, file) " {{{

	let ret = {'success' : 0}

	let ret['errmsg'] = s:PW_valid_config(a:site_name)
	if ret['errmsg'] != ''
		return ret
	endif

	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'info'
	let param['refer'] = a:page
	let param['file'] = a:file

	let info = {
		\ "site" : a:site_name,
		\ "page" : a:page,
	\}
	let retdic = s:PW_request('info_attach_file', param, info, 'POST', {})
	if !retdic['success']
		let ret['errmsg'] = 'get infomation of attach file ' . a:file . ' failed'
		return ret
	endif

	let body = split(retdic['content'], '\n')
	let title = filter(copy(body), 'v:val =~ "<title>.*</title>"')
	if len(title) == 0
		let ret['errmsg'] = 'system error: <title> not found'
		return ret
	endif

	if title[0] !~ ".*添付ファイルの情報.*"
	" @JPMES
		if title[0] =~ ".*そのファイルは見つかりません.*"
			let ret['errmsg'] = 'info_attach_file() the file is not attached: ' . a:file
		else
			echo a:000
			echo body
			let ret['errmsg'] = 'info_attach_file() failed: ' . title[0]
		endif
		return ret
	endif

	let body = filter(body, "v:val =~ ' <dd>.*'")
	let body = map(body, "substitute(v:val, ' <dd>\\(.*\\)</dd>', '\\1', '')")
	let ret.data = body
	let ret['success'] = 1
	return ret
endfunction " }}}

function! pukiwiki#delete_attach_file(site_name, page, file) " {{{

	let attach_info = pukiwiki#info_attach_file(a:site_name, a:page, a:file)
	if attach_info['success'] == 0
		call s:VITAL.print_error(attach_info['errmsg'])
		return -1
	endif

	let sitedict = g:pukiwiki_config[a:site_name]
	let pass = s:get_password(sitedict)

	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'delete'
	let param['pass'] = pass
	let param['refer'] = a:page
	let param['file'] = a:file

	let info = {
		\ "site" : a:site_name,
		\ "page" : a:page,
	\}
	let retdic = s:PW_request('delete_attach_file', param, info, 'POST', {})
	if !retdic['success']
		call s:VITAL.print_error('delete the attach file filed: ' . a:file)
		return -1
	endif

	let body = split(retdic['content'], '\n')
	let title = substitute(retdic['content'], '^.*<title>\([^\n]*\)</title>.*$', '\1', '')

	" @JPMES
	if title =~ ".*添付ファイルの情報.*"

		" パスワード間違いなどによるエラー.
		" request は正常に帰ってきて,
		" font-weight:bold でエラーが復帰される
		let body = filter(body, 'v:val =~ "^<p style=\"font-weight:bold\">"')
		if len(body) > 0
			let title = substitute(body[0], '<[^>]*>', '', 'g')
		else
			let title = "delete attach file failed"
		endif
		call s:VITAL.print_error(title)
		return -1
	endif
	unlet body
	if title =~ '.*からファイルを削除しました'
	" @JPMES
		call s:set_password(sitedict, pass)
		return 0
	else
		call s:VITAL.print_error("delete failed: " . title)
		return -1
	endif

"	let param = attach_info
"
"	let retdic = s:PW_request('delete_attach_file', param, a:page, 'POST')
"	" a:page にそのファイルは見つかりません
"	echo retdic
"	return 0
endfunction " }}}

function! pukiwiki#get_attach_files() "{{{

	" 普通はない. 初期化されているはず
	if !s:PW_is_init()
		return []
	endif

	" 添付ファイルの一覧
	let page = b:pukiwiki_info.page

	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'list'
	let param['refer'] = page

	let retdic = s:PW_request('show_attach', param, b:pukiwiki_info, 'GET', {})
	if !retdic['success']
		return 0
	endif

	let body = split(retdic['content'], '\n')
	let body = filter(body, 'v:val =~ "<li><a href=\".*</a>$"')
	let body = map(body, 'substitute(v:val, "\\s*<li><a href=[^>]* title=.\\(.*\\).>\\(.*\\)</a>", "\\1\\t\\2", "")')
	let body = map(body, '[substitute(v:val, ".*\\t", "", ""), substitute(v:val, "\\t.*", "", "")]')
	" ファイル名, 情報
	let body = map(body, '[s:HTML.decodeEntityReference(v:val[0]), v:val[1]]')
	return body
endfunction "}}}

" @TODO バイナリファイルの場合にファイルが壊れることがある.
" vital.vim で r = join(readfile(file, "b"), "\n")
" pukiwiki.vim で writefile(split(r, "\n", 1), ofile, "b")
" 00 01 02 03 04 05 のファイルが
" 0a 01 02 03 04 05 になる
function! pukiwiki#download_attach_file(site_name, page, file, ofile)

	let ret = s:PW_valid_config(a:site_name)
	if ret
		call s:VITAL.print_error(ret)
		return -1
	endif

	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'open'
	let param['refer'] = a:page
	let param['file'] = a:file

	let info = {
		\ "site" : a:site_name,
		\ "page" : a:page,
	\}

	let settings = {}
	let settings.outputFile = a:ofile
	let retdic = s:PW_request('download_attach_file', param, info, 'GET', settings)
	if !retdic.success
		return -1
	endif
	return 0
endfunction
" }}}

function! pukiwiki#bookmark() " {{{
	" 現在のページをブックマークする
	if !s:PW_is_init()
		throw "pukiwiki.vim is not executed."
	endif

	if !exists('g:pukiwiki_bookmark')
		throw "g:pukiwiki_bookmark is not defined"
	endif
	if filereadable(g:pukiwiki_bookmark)
		let lines = readfile(g:pukiwiki_bookmark)
		if lines[0] != "pukiwiki.bookmark.v1."
			" 上書きしていいものか...
			throw "g:pukiwiki_bookmark is invalid"
		endif
	else
		let lines = ["pukiwiki.bookmark.v1."]
	endif

	let site = b:pukiwiki_info.site
	let page = b:pukiwiki_info.page
	call add(lines, site . "," . page)
	call writefile(lines, g:pukiwiki_bookmark)
	echo "success: add bookmark"
endfunction " }}}

" page open s:[top/attach/list/search] {{{
function! s:PW_get_top_page(site_name) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let top = get(sitedict, 'top','FrontPage')

	return s:PW_get_edit_page(a:site_name, top, 1)

endfunction "}}}

function! s:PW_show_attach(site_name, page) "{{{
"----------------------------------------------
" 添付ファイル用の画面を表示する.
" 表示せずにコマンドだけ・・・のほうがいいのかな
"----------------------------------------------

	let files = pukiwiki#get_attach_files()
	let files = map(files, '"- " . v:val[0] . "\t\t(" . v:val[1] . ")"')

	call s:PW_newpage(a:site_name, a:page, 'attach')
	call s:PW_set_statusline(a:site_name, a:page)
	let h = s:PW_insert_header(a:site_name, a:page)
	" 添付ファイル一覧
	" @JPMES
	call setline(h + 0, "添付ファイル一覧 [[" . a:page . "]]")
	call setline(h + 1, "")
	call map(files, 'setline(v:key + h + 2, v:val)')

	call s:PW_endpage(a:site_name, a:page, 1)
endfunction "}}}

function! s:PW_show_page_list() "{{{
	let param = {}
	let param['cmd'] = 'list'

	let info = {
	\	"site" : b:pukiwiki_info["site"],
	\}
	let retdic = s:PW_request('show_page_list', param, info, 'GET', {})
	if !retdic['success']
		return
	endif
	let body = retdic['content']

	let site = b:pukiwiki_info.site
	let page = "cmd=list"
	call s:PW_newpage(site, page, 'pagelist')
	call s:PW_set_statusline(site, page)

	" がんばって加工
	let bodyl = split(body, "\n")
	let bodyl = filter(bodyl, 'v:val =~ "^\\s*<li><a href=" || v:val =~ "^\\s*<li><a id="')
	let bodyl = map(bodyl, 'substitute(v:val, "^\\s*<li><a href.*>\\(.*\\)</a><small>\\(.*\\)</small>.*$", "- [[\\1]]\\t\\2", "")')
	let bodyl = map(bodyl, 'substitute(v:val, "^\\s*<li><a id.*><strong>\\(.*\\)</strong></a>.*$", "*** \\1", "")')
	let bodyl = map(bodyl, 's:HTML.decodeEntityReference(v:val)')

	let h = s:PW_insert_header(site, page)
	call map(bodyl, 'setline(v:key + h, v:val)')

	" page 名しかないので, decode しなくても良い気がする.
	" single quote &apos;  &#xxxx などはやらないといけないらしい.


	call s:PW_endpage(site, page, 1)
endfunction "}}}

function! s:PW_show_search() "{{{

	let site = b:pukiwiki_info.site

	let word = input('keyword: ')
	if word == ''
		return
	endif
	let andor = input('(And/or): ')
	let type =  (andor =~? 'o\%[r]') ? 'OR' : 'AND'

	let param = {}
	let param['word'] = word
	let param['type'] = type
	let param['cmd'] = 'search'

	let info = {
		\ "site" : site,
	\}
	let retdic = s:PW_request('show_search', param, info, 'POST', {})
	if !retdic['success']
		return
	endif


	let page = 'cmd=search'
	call s:PW_newpage(site, page, 'search')
	call s:PW_set_statusline(site, page)

	" がんばって加工
	let bodyl = split(retdic['content'], '\n')
	let bodyl = filter(bodyl, 'v:val =~ "^\\s*<li><a href=" || v:val =~ "^<strong class="')
	let bodyl = map(bodyl, 'substitute(v:val, "^\\s*<li><a href=[^>]*>\\(.*\\)</a>\\(.*\\)</li>.*$", "- [[\\1]]\\t\\2", "")')
	let bodyl = map(bodyl, 'substitute(v:val, "<[^>]*>", "", "g")')
	let bodyl = map(bodyl, 's:HTML.decodeEntityReference(v:val)')
	let mes = remove(bodyl, -1)
	call insert(bodyl, mes, 0)

	" 最終行に [... 10 ページ見つかりました] メッセージ
	" それを最初にだす
	" @REG
	let h = s:PW_insert_header(site, page)
	call map(bodyl, 'setline(v:key + h, v:val)')
	call s:PW_endpage(site, page, 1)
endfunction "}}}
" }}}

function! s:get_password(sitedict) " {{{
	if !has_key(a:sitedict, 'password')
		let pass = input('password: ')
	else
		let pass = a:sitedict['password']
	endif

	return pass
endfunction " }}}

function! s:set_password(sitedict, pass) " {{{
	let a:sitedict['password'] = a:pass
endfunction " }}}

function! pukiwiki#fileupload() range "{{{

	if !s:PW_is_init()
		return
	endif

	let site = b:pukiwiki_info["site"]
	let page = b:pukiwiki_info["page"]

	let sitedict = g:pukiwiki_config[site]

	let pass = s:get_password(sitedict)

	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'post'
	let param['refer'] = page
	let param['pass'] = pass

    for linenum in range(a:firstline, a:lastline)
        "Replace loose ampersands (as in DeAmperfy())...
        let curr_line   = getline(linenum)
		if curr_line =~ '^\s\*$' || curr_line == ""
			continue
		endif

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

		let param['attach_file'] = curr_line
		let retdic = s:PW_request('get_page', param, b:pukiwiki_info, 'MULT', {})
		if !retdic['success']
			return 0
		endif

		let body = retdic['content']
		let body = substitute(body, '^.*<h1 class="title">\(.*\)</h1>.*$', '\1', '')
		let body = substitute(body, '<a href=".*">\(.*\)</a>', '[[\1]]', '')
		call setline(linenum, curr_line . "\t" . body)

		" @JPMES
		if body =~ '.*パスワード.*'
			" パスワード誤り
			if has_key(sitedict, 'password')
				call remove(sitedict, 'password')
			endif
			break
		elseif body =~ '.*アップロード.*'
			call s:set_password(sitedict, pass)
		" @TODO パスワード誤りで、ここを通らないことを確認
"		elseif body =~ '.*同じファイル名.*'
"			call s:set_password(sitedict, pass)
		endif
    endfor

endfunction "}}}

" g:motion {{{
function! pukiwiki#jump_menu(pname) " {{{

	if !s:PW_is_init()
		call s:VITAL.print_error('vim-pukiwiki has not initialized')
		return
	endif

	let site = b:pukiwiki_info["site"]
	let page = b:pukiwiki_info["page"]
	let ptyp = b:pukiwiki_info["type"]

	if a:pname == 'トップ' || a:pname == 'top'
		call s:PW_get_top_page(site)
	elseif a:pname == 'リロード' || a:pname == 'reload'
		if ptyp == 'attach'
			call s:PW_show_attach(site, page)
		elseif ptyp == 'pagelist'
			call s:PW_show_page_list()
		elseif ptyp == 'search'
			" @TODO 本当は検索語を覚えていて呼び出しのやり直しすべきだろう
			call s:PW_show_search()
		elseif page == 'FormattingRules' || page == 'RecentChanges'
			call s:PW_get_source_page(site, page)
		else
			call s:PW_get_edit_page(site, page, 0)
		endif
	elseif a:pname == '新規' || a:pname == 'new'
		let page = input('page name: ')
		if page == ''
			return
		endif
		call s:PW_get_edit_page(site, page, 1)
	elseif a:pname == '一覧' || a:pname == 'list'
		call s:PW_show_page_list()
	elseif a:pname == '単語検索' || a:pname == 'search'
		call s:PW_show_search()
	elseif a:pname == '添付' || a:pname == 'attach'
		call s:PW_show_attach(site, page)
	elseif a:pname == '最終更新' || a:pname == 'recent'
		let page = 'RecentChanges'
		call s:PW_get_source_page(site, page)
	elseif a:pname == 'ヘルプ' || a:pname == 'help'
		let page = 'FormattingRules'
		call s:PW_get_source_page(site, page)
	endif
	return
endfunction " }}}

" jumpdicts {{{
function! pukiwiki#jumpdict_register(dict) " {{{

	if !s:VITAL.is_dict(a:dict)
		call s:VITAL.print_error("pukiwiki#jumpdict_register(): invalid parameter")
		return
	endif

	if !has_key(a:dict, 'name') ||
	\  !has_key(a:dict, 'format') ||
	\  !has_key(a:dict, 'func')
		call s:VITAL.print_error("pukiwiki#jumpdict_register(): invalid parameter")
		return
	endif

	if !s:VITAL.is_string(a:dict.name) ||
	\  !s:VITAL.is_string(a:dict.format) ||
	\  !s:VITAL.is_funcref(a:dict.func)
		call s:VITAL.print_error("pukiwiki#jumpdict_register(): invalid parameter")
		return
	endif

	if has_key(a:dict, 'available') && !a:dict.available()
		return
	endif
	call pukiwiki#jumpdict_unregister(a:dict.name)
	call add(s:pukiwiki_jumpdicts, a:dict)
endfunction " }}}
function! pukiwiki#jumpdict_unregister(name) " {{{
	call filter(s:pukiwiki_jumpdicts, 'v:val.name !=#' . string(a:name))
endfunction " }}}

" {{{ 画像ファイルを開く. &ref(), #ref()
let s:doc_openimage = {
\  'name' : 'image',
\  'format' : '[&#]ref(\([^,)]*\)',
\  'viewer' : [{
\		'name' : 'eog',
\		'exec' : 'eog -w "%s"'
\	}, {
\		'name' : 'display',
\		'exec' : 'display "%s"'
\	}],
\}

function! s:doc_openimage.func(cur, info) "{{{
	let site = a:info["site"]
	let page = a:info["page"]
	let enc = a:info["enc"]
	let sitedict = g:pukiwiki_config[site]
	let url = sitedict['url']

	let page = s:VITAL.iconv(page, &enc, enc)
	let page = s:PW_urlencode(page)

	let filename = a:cur[5:]
	let filename = substitute(filename, './', '', '')
	let filename = s:VITAL.iconv(filename, &enc, enc)
	let filename = s:PW_urlencode(filename)

	let url2 = printf("%s/index.php?plugin=attach&refer=%s&openfile=%s",
\		 url, page, filename)

	" @TODO コマンドを変更できるようにする.
	let cmdl = ""
	for cmd in s:doc_openimage.viewer
		if executable(cmd.name)
			let cmdl = printf(cmd.exec, url2)
			break
		endif
	endfor

	if cmdl == ""
		return
	endif

	if g:pukiwiki_debug > 3
		echomsg "[&#]ref2: " . cmdl
	endif

	call vimproc#system_bg(cmdl)
	return
endfunction "}}}

function! s:doc_openimage.available() " {{{
	for cmd in s:doc_openimage.viewer
		if executable(cmd.name)
			return 1
		endif
	endfor
	return 0
endfunction " }}}

call pukiwiki#jumpdict_register(s:doc_openimage)

" }}}

" {{{ 数式を開く
let s:doc_openmath = {
\  'name' : 'math',
\  'format' : '[&#]math(.*);'}

function! s:doc_openmath.available() " {{{
	return executable('display')
\		&& executable('dvipng')
\		&& executable('platex')
endfunction " }}}

" 数式ファイル生成して開く.
function! s:doc_openmath.func(cur, info) "{{{
	let tmpfile = tempname()
	let str = a:cur[6:-3]
	let lines = [
\		'\documentclass[12pt]{article}',
\		'\usepackage{amsmath}',
\		'\usepackage{amsfonts}',
\		'\oddsidemargin=0in',
\		'\textwidth=6.5in',
\		'\topmargin=0in',
\		'\textheight=609pt',
\		'\pagestyle{empty}',
\		'\begin{document}',
\		'{\large',
\		'\[',
\		str,
\		'\]',
\		'}',
\		'\end{document}',
\	]

	let nowdir = getcwd()
	execute ":lcd " . s:dirname(tmpfile)
	try
		call writefile(lines, tmpfile . ".tex")
		call s:VITAL.system("platex " . tmpfile)
		if !filereadable(tmpfile . ".dvi")
			call s:VITAL.print_error("platex failed")
			return
		endif

		call s:VITAL.system("dvipng -T tight -o " . tmpfile . ".png " . tmpfile . ".dvi")
		if !filereadable(tmpfile . ".png")
			call s:VITAL.print_error("dvipng failed")
			return
		endif

		" ゴミ掃除が必要なので bg にしない
		call s:VITAL.system("display " . tmpfile . ".png")
	finally
		execute ":lcd " . nowdir

		call delete(tmpfile . ".tex")
		call delete(tmpfile . ".dvi")
		call delete(tmpfile . ".png")
		call delete(tmpfile . ".aux")
		call delete(tmpfile . ".log")
	endtry
endfunction "}}}

call pukiwiki#jumpdict_register(s:doc_openmath)

unlet s:doc_openmath
" }}}

function! pukiwiki#jump()  "{{{
	if !s:PW_is_init()
		return
	endif

	let has_header = b:pukiwiki_info["header"]
	if has_header && line('.') < s:pukiwiki_header_row
		" ヘッダ部分
		let cur = s:PW_matchstr_undercursor('\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]')
	else
		let cur = s:PW_matchstr_undercursor(s:pukiwiki_bracket_name)
	endif

	if cur == ''
		let line = getline('.')
		if line == '#contents'
			setlocal foldmethod=expr foldexpr=getline(v:lnum)=~'^*'?'>1':'='
			return
		endif

		for jumpdict in s:pukiwiki_jumpdicts
			let cur = s:PW_matchstr_undercursor(jumpdict.format)
			if cur != ''
				call jumpdict.func(cur, copy(b:pukiwiki_info))
				return
			endif
		endfor

		return
	endif

	if &modified
		call s:VITAL.print_error("No write since last change")
		return
	endif

	let cur = cur[2:-3]
	if has_header && line('.') < s:pukiwiki_header_row
		return pukiwiki#jump_menu(cur)
	endif

	" エイリアスはとにかく削除
	let cur = substitute(cur, '.*>', '', '')
	let anchor = substitute(cur, '^.*#', '#', '')
	let cur = substitute(cur, '#.*', '', '')

	call s:PW_get_edit_page(b:pukiwiki_info["site"], cur, 1)
	if anchor =~ "#"
		let p = search('^\*\{1,3}.*\[' . anchor . '\]', 'c')
		if p == 0
			" &anchor() を探す.
			let p = search('&aname(' . anchor[1:] . ')', 'c')
		endif
	endif
endfunction "}}}

function! pukiwiki#move_next_bracket() "{{{
	call search(s:pukiwiki_bracket_name)
"	let tmp = @/
"	let @/ = tmp
endfunction "}}}

function! pukiwiki#move_prev_bracket() "{{{
	call search(s:pukiwiki_bracket_name, 'b')
endfunction "}}}
" }}}

" s:alice.vim {{{
function! s:clear_undo() " {{{
	" undo 履歴を消去する, @see *clear-undo*
	let oldundolevel = &undolevels
	execute ":setlocal undolevels=-1"
	execute "normal a \<BS>\<Esc>"
	execute ":setlocal undolevels=" . oldundolevel
	unlet oldundolevel
endfunction " }}}

function! s:PW_urlencode(str) "{{{
" 1) [._-] はそのまま
" 2) [A-Za-z0-9] もそのまま。
" 3) 0x20[ ] ==> 0x2B[+]
" 以上の3つの規則に当てはまらない文字は、 全て、 "%16進数表記"に変換する。
" Return URL encoded string

  let result = ''
  for i in range(strlen(a:str))
    let ch = a:str[i]
    if ch =~ '[-_.0-9A-Za-z]'
      let result .= ch
    else
      let result .= printf("%%%02X", char2nr(ch))
    endif
endfor
  return result
endfunction "}}}

function! s:PW_echokv(key, value)  " {{{
	echohl String | echo a:key | echohl None
	echon '=' . a:value
endfunction "}}}

" matchstr() for under the cursor
" from alice.vim by MURAOKA Taro <koron@tka.att.ne.jp>
function! s:PW_matchstr_undercursor(mx) "{{{
  let column = col('.')
  let mx = '\m\%<'.(column + 1).'c'.a:mx.'\%>'.column.'c'
  return matchstr(getline('.'), mx)
endfunction "}}}

" サーバからの文字列をローカルに変更
function! s:PW_iconv_s(val, fromenc) " {{{
	return s:VITAL.iconv(a:val, a:fromenc, &enc)
endfunction " }}}

" vital.vim system/filepath.vim
function! s:dirname(path) " {{{
  let path = a:path
  let orig = a:path

  let path = s:remove_last_separator(path)
  if path == ''
    return orig    " root directory
  endif

  let path = fnamemodify(path, ':h')
  return path
endfunction " }}}

" Remove the separator at the end of a:path.
function! s:remove_last_separator(path) " {{{
  let sep = s:separator()
  let pat = (sep == '\' ? '\\' : '/') . '\+$'
  return substitute(a:path, pat, '', '')
endfunction " }}}

" Get the directory separator.
function! s:separator() " {{{
  return fnamemodify('.', ':p')[-1 :]
endfunction " }}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:

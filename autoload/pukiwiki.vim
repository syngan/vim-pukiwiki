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

" option {{{

scriptencoding euc-jp

"}}}

" variables {{{
let s:pukiwiki_history = []

let s:pukiwiki_header_row = 3
lockvar s:pukiwiki_header_row

let s:pukiwiki_ro_menu = "\n"
	\ . "[[トップ]] [[添付]] [[リロード]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]\n"
	\ . "------------------------------------------------------------------------------\n"
lockvar s:pukiwiki_ro_menu
"let s:pukiwiki_bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:pukiwiki_bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:pukiwiki_bracket_name = '\[\[\_.\{-}\]\]'
"
"
lockvar s:pukiwiki_bracket_name

" }}}

" vital.vim {{{
let s:VITAL = vital#of('vim-pukiwiki')
let s:HTML = s:VITAL.import('Web.Html')
let s:HTTP = s:VITAL.import('Web.Http')
" }}}

" debug {{{
function! pukiwiki#buf_vars() "{{{
	" デバッグ用
	if exists('b:pukiwiki_site_name')
		call s:PW_echokv('site_name' , b:pukiwiki_site_name)
		let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
		call s:PW_echokv('url' , sitedict['url'])
		call s:PW_echokv('top' , sitedict['top'])
		call s:PW_echokv('enc' , sitedict['encode'])
	else
		call s:PW_echokv('site_name' , 'undefined')
	endif
	if exists('b:pukiwiki_page')
		call s:PW_echokv('page'      , b:pukiwiki_page)
	else
		call s:PW_echokv('page'      , 'undefined')
	endif
	if exists('b:pukiwiki_digest')
		call s:PW_echokv('digest'    , b:pukiwiki_digest)
	else
		call s:PW_echokv('digest'    , 'undefined')
	endif

endfunction "}}}
"}}}

function! pukiwiki#PukiWiki(...) "{{{
	if !s:PW_env_check()
		return
	endif

	if !call("s:PW_read_pukiwiki_list", a:000)
		" s:VITAL.print_error('ブックマークの読み込みに失敗しました。')
		return
	endif
endfunction "}}}

function! s:PW_read_pukiwiki_list(...) "{{{
" bookmark
" PukiVim [ SiteName [ PageName ]]
"
	if &modified
		" @TODO 複数の同じ window を開いているときは skip したい.
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
		let site_name = input('site name: ')
	else
		let site_name = a:1
	endif

	let msg = s:PW_valid_config(site_name)
	if msg != ''
		call s:VITAL.print_error(msg)
		return 0
	endif

	let dict = g:pukiwiki_config[site_name]
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
	if !exists('g:pukiwiki_config')
		return 'g:pukiwiki_config is not defined.'
	endif
	if !s:VITAL.is_dict(g:pukiwiki_config)
		return 'g:pukiwiki_config is not a dictionary.'
	endif
	if !has_key(g:pukiwiki_config, a:site_name)
		return ('site "' . site_name . '" is not defined.')
	endif

	let sitedict = g:pukiwiki_config[a:site_name]
	if !s:VITAL.is_dict(sitedict)
		return ('g:pukiwiki_config[' . a:site_name . '] is not a dictionary.')
	endif

	if (!has_key(sitedict, 'url'))
		return .print_error('g:pukiwiki_config[' . a:site_name . '].url is not defined.')
	endif

	return ""

endfunction "}}}

function! s:PW_is_init() " {{{
	if !exists('b:pukiwiki_site_name')
		return 0
	endif

	return 1
endfunction "}}}

function! s:PW_gen_multipart(settings, param) " {{{
	 " multipart-form を生成する
	if !s:VITAL.is_dict(a:param)
		throw "invalid argument"
	endif


	" @TODO 本当はファイル内に同じ文字列がないこと、を確認する必要があるが...
	let b = "---------------------11285676"
	if has('reltime')
		let b .= substitute(reltimestr(reltime()), "\\X", '', 'g')
	else
"		let b .= substitute(tempname().localtime(), "[^A-Za-z0-9]", '', 'g')
		let b .= substitute(localtime(), "[^A-Za-z0-9]", '', 'g')
	endif
	let a:settings.contentType = "multipart/form-data; boundary=" . b
	let ret = ""
	let CRLF = "\r\n"
	let b = "--" . b
	for key in keys(a:param)
		let ret .= b . CRLF
		if key == "attach_file"
			let ret .= 'Content-Disposition: form-data; name="attach_file"; filename="' . a:param[key] . '"' . CRLF
			let ret .= 'Content-Type: application/octet-stream' . CRLF

			let attach_body = readfile(a:param[key], 'b')
			let buf = join(attach_body, "\n")
"			let ret .= 'Content-Length: ' . len(buf) . CRLF
			let ret .= CRLF . buf . CRLF
		else
			let ret .= 'Content-Disposition: form-data; name="' . key . '"' . CRLF
			let ret .= CRLF . a:param[key] . CRLF
		endif
	endfor

	let ret .= b . '--' . CRLF
	return ret
endfunction " }}}

function! s:PW_request(funcname, param, page, method) " {{{
" Web サーバにリクエストを送り、結果を受け取る.
" @return success をキーに持つ辞書
	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']

	let settings = {}
"	let settings['client'] = 'wget'
	let settings['url'] = url
	let settings['method'] = a:method
	let settings['maxRedirect'] = 0
"	let a:param['page'] = s:PW_urlencode(enc_page)
	let pm = a:param
	if a:page != ''
		if s:VITAL.is_dict(a:param) 
			let pm['page'] = s:VITAL.iconv(a:page, &enc, enc)
		else
			let pm .= '&page=' . s:VITAL.iconv(a:page, &enc, enc)
		endif
	endif
	if a:method == 'POST'
		let settings['data'] = pm
	elseif a:method == 'GET'
		let settings['param'] = pm
	elseif a:method == 'MULT'
		" multipart/form-data
		let settings['data'] = s:PW_gen_multipart(settings, pm)
		let settings['method'] = 'POST'
	else
		throw 'invalid argument: method'
	endif
	try
		let retdic = s:HTTP.request(settings)
	catch
		call s:VITAL.print_error(a:funcname . '() failed: ' . v:exception)
		return {'success' : 0}
	endtry
	if !has_key(retdic, 'success')
		call s:VITAL.print_error(a:funcname . '() failed: ')
		return {'success' : 0}
	endif
	if !retdic['success']
		if retdic['status'] == 302
			" 書き込み時(PW_write())に成功扱いにする.
			let retdic['success'] = 1
		else
			call s:VITAL.print_error(a:funcname . '() failed: ' . retdic['status'] . ' ' . retdic['statusText'])
			return retdic
		endif
	endif
	let retdic['content'] = s:VITAL.iconv(retdic['content'], enc, &enc)
	return retdic
endfunction "}}}

function! s:PW_newpage(site_name, page, pagetype) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let enc = sitedict['encode']

	silent execute ":e ++enc=" . enc . " " . tempname()
	execute ":setlocal modifiable"
	execute ":setlocal indentexpr="
	execute ":setlocal noautoindent"
	execute ":setlocal paste"
	execute ':setlocal nobuflisted'

	execute ":setlocal filetype=pukiwiki"

	" nnoremap {{{
	if !g:pukiwiki_no_default_key_mappings
		nnoremap <silent> <buffer> <CR>    :call pukiwiki#jump()<CR>
		nnoremap <silent> <buffer> <Tab>   :call pukiwiki#move_next_bracket()<CR>
		nnoremap <silent> <buffer> <S-Tab> :call pukiwiki#move_prev_bracket()<CR>
	"	nnoremap <silent> <buffer> B       :call pukiwiki#get_last_page()<CR>
	endif
	" }}}

	let b:pukiwiki_site_name = a:site_name
	let b:pukiwiki_page      = a:page
	let b:pukiwiki_page_type = a:pagetype
endfunction "}}}

function! s:PW_endpage(site_name, page, readonly) "{{{
	execute "normal! gg"
	execute ':setlocal nobuflisted'
	execute ":set nomodified"
	if a:readonly
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
	endif
	execute ":setlocal noswapfile"
	execute ":setlocal nopaste"
	silent! execute ":redraws!"
endfunction "}}}

function! s:PW_gen_statusline_str(site_name, page) "{{{
	let status_line = a:page . ' ' . a:site_name
"	let status_line = a:page
	let status_line = escape(status_line, ' ')
	return status_line
endfunction "}}}

function! s:PW_set_statusline(site_name, page) "{{{
	let status_line = s:PW_gen_statusline_str(a:site_name, a:page)
	silent! execute ":f " . status_line
	return status_line
endfunction "}}}

function! s:PW_get_digest(str) "{{{
	" [[編集]] 画面から digest を取得する
	let s = matchstr(a:str,
	\     '<input type="hidden" name="digest" value="\zs.\{-}\ze" />')
	return s
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
		execute "normal! gg0i" . a:site_name . " " . a:page . s:pukiwiki_ro_menu
	endif
endfunction " }}}

function! s:PW_get_page(site_name, page, pwcmd, opennew) "{{{
" ページを開く
" pwcmd = "edit" or "source"

	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']
	let b:pukiwiki_site_name = a:site_name
	let param = {}
	let param['cmd'] = a:pwcmd
	let retdic = s:PW_request('get_page', param, a:page, 'GET')
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
			call s:VITAL.print_error('ページの読み込みに失敗しました。認証が必要です。')
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
		execute 'normal! ggdG'
		let @" = regbak
	endif


	call s:PW_insert_header(a:site_name, a:page)
"	silent! execute "normal! ihistory>>>>>" . len(s:pukiwiki_history) . "\n"
"	for elm in s:pukiwiki_history
"		silent! execute "normal! i" . elm[4] . "\n"
"	endfor
"	silent! execute "normal! ihistory<<<<<" . len(s:pukiwiki_history) . "\n"

	let msg = s:HTML.decodeEntityReference(msg)
	silent! execute "normal! i" . msg


	let b:pukiwiki_digest = digest
	let b:pukiwiki_page   = a:page

	let status_line = s:PW_set_statusline(b:pukiwiki_site_name, b:pukiwiki_page)

	" undo 履歴を消去する, @see *clear-undo*
	let oldundolevel = &undolevels
	execute ":setlocal undolevels=-1"
	execute "normal a \<BS>\<Esc>"
	execute ":setlocal undolevels=" . oldundolevel
	unlet oldundolevel

	if a:pwcmd == 'edit'
		augroup PukiWikiEdit
			" 不要な autocmd は消去したい @TODO
			execute "autocmd BufWriteCmd " . status_line . " call s:PW_write()"
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

	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
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
		let last_confirm = s:PW_yesno('タイムスタンプを変更する？: ', 'y')
		if last_confirm
			let notimestamp = 'true'
		endif
		unlet last_confirm
	endif

	" ヘッダの削除. ユーザがヘッダを修正すると
	" 書き込みが壊れるだめな仕様
	" @REG
	if g:pukiwiki_show_header
		let regbak = @"
		silent! execute "normal! gg" . s:pukiwiki_header_row . "D"
		let @" = regbak
	else
		silent! execute "normal! gg"
	endif
	execute ":setlocal fenc="

	" urlencode
	let body = []

	let cl = 1
	while cl <= line('$')
		let line = getline(cl)
		let line = s:VITAL.iconv(line, &enc, enc)
		let line = s:PW_urlencode(line)
		call add(body, line)
		let cl = cl + 1
	endwhile

	" urlencode した本文前にその他の情報設定
	let param = {}
	let cmd = "encode_hint=" . s:PW_urlencode(s:VITAL.iconv('ぷ', &enc, enc))
	let param['cmd'] = 'edit'
	let param['page'] = s:PW_urlencode(s:VITAL.iconv(b:pukiwiki_page, &enc, enc))
	let param['digest'] = b:pukiwiki_digest
	let param['write'] = s:VITAL.iconv('ページの更新', &enc, enc)
	let param["notimestamp"] = notimestamp
	let param["original"] = ''
	let param["msg"] = join(body, '%0A')
	let paramstr = s:PW_joindictstr(param)
	unlet param

	let retdic = s:PW_request('write', paramstr, b:pukiwiki_page, 'POST')
	unlet paramstr
	if !retdic['success']
		return 0
	endif

	" 書き込みが成功すると PukiWiki が
	" locationヘッダーを吐く & 302 を返す
	if retdic['status'] == 302
		call s:PW_get_edit_page(b:pukiwiki_site_name, b:pukiwiki_page, 0)

		" 元いた行に移動
		execute "normal! " . lineno . "G"

		echo 'update ' . b:pukiwiki_page . ' @ ' . b:pukiwiki_site_name
		return 0
	endif

	" pukiwiki 上で何かのイベントが起こった.
	"  - ページの削除
	"  - 更新の衝突
	let bodyr = retdic['content']

	" もう少しまともな判定方法はないのか?
	if bodyr =~ '<title>\_.\{-}を削除しました\_.\{-}<\/title>'
		let page = b:pukiwiki_page
		call s:PW_get_edit_page(b:pukiwiki_site_name, top, 0)
		echo page . ' を削除しました'
		return
	endif

	if g:pukiwiki_debug
		echo retdic
	endif
	" 失敗
	execute ":undo"
	execute ":set nomodified"
	execute ":setlocal nomodifiable"
	execute ":setlocal readonly"
	let site_name = b:pukiwiki_site_name
	let page      = b:pukiwiki_page

	" 書き込みしようとしたバッファの名前の前に'ローカル'を付けて
	" 現在のサーバー上の内容を取得して'diffthis'を実行する。
	call s:PW_set_statusline(b:pukiwiki_site_name, 'ローカル ' . b:pukiwiki_page)
	execute ":diffthis"
	execute ":new"

	call s:PW_get_edit_page(site_name, page, 0)
	execute ":diffthis"
	if g:pukiwiki_debug
		echo "digest=[" . b:pukiwiki_digest . "] cmd=[" . cmd . "]"
		echo "&enc=" . &enc . ", enc=" . enc . ", page=" . b:pukiwiki_page
		echo "s:VITAL.iconv=" . Byte2hex(s:VITAL.iconv(b:pukiwiki_page, &enc, enc))
		echo "urlen=" . s:PW_urlencode(s:VITAL.iconv( b:pukiwiki_page, &enc, enc))
	endif
	call s:VITAL.print_error('更新の衝突が発生したか、その他のエラーで書き込めませんでした。')
	return 0
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
		if page == b:pukiwiki_page && len(s:pukiwiki_history) > 0
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

function! pukiwiki#info_attach_file(site_name, page, file) " {{{

	let ret = {'success' : 0}

	let ret['errmsg'] = s:PW_valid_config(a:site_name)
	if ret['errmsg'] != ''
		return ret
	endif

	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']
	let enc_page = a:page

	let param = {}
	let param['encode_hint'] = 'ぷ'
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'info'
	let param['refer'] = enc_page
	let param['file'] = a:file

	let site_bak = b:pukiwiki_site_name
	let b:pukiwiki_site_name = a:site_name
	let retdic = s:PW_request('info_attach_file', param, a:page, 'POST')
	let b:pukiwiki_site_name = site_bak
	if !retdic['success']
		ret['errmsg'] = 'get infomation of attach file ' . a:file . ' failed'
		return ret
	endif

	let body = split(retdic['content'], '\n')
	let title = filter(copy(body), 'v:val =~ "<title>.*</title>"')
	if len(title) == 0
		let ret['errmsg'] = '<title> not found'
		return ret
	endif

	if title[0] !~ ".*添付ファイルの情報.*"
		if title[0] =~ ".*そのファイルは見つかりません.*"
			let ret['errmsg'] = 'file not attached: ' . a:file
		else
			let ret['errmsg'] = 'title is not attach file info'
		endif
		return ret
	endif

	let body = filter(body, "v:val =~ '.*<input type=.hidden. name=.*'")
	for vv in body
		let key = substitute(vv, '.*name="', '', '')
		let key = substitute(key, '".*', '', '')
		let val = substitute(vv, '.*value="', '', '')
		let val = substitute(val, '".*', '', '')

		if len(key) > 0
			let ret[key] = val
		endif
	endfor

	let ret['success'] = 1
	return ret
endfunction " }}}

function! pukiwiki#delete_attach_file(site_name, page, file) " {{{

	let attach_info = pukiwiki#info_attach_file(a:site_name, a:page, a:file)
	if attach_info['success'] == 0
		call s:VITAL.print_error(attach_info['errmsg'])
		return -1
	endif

	let attach_info['pcmd'] = 'delete'

	let sitedict = g:pukiwiki_config[a:site_name]
	let pass = s:get_password(sitedict)
	let attach_info['pass'] = pass

	let site_bak = b:pukiwiki_site_name
	let b:pukiwiki_site_name = a:site_name
	let retdic = s:PW_request('delete_attach_file', attach_info, a:page, 'POST')
	let b:pukiwiki_site_name = site_bak
	if !retdic['success']
		call s:VITAL.print_error('delete the attach file filed: ' . a:file)
		return -1
	endif

	let body = split(retdic['content'], '\n')
	let title = substitute(retdic['content'], '^.*<title>\([^\n]*\)</title>.*$', '\1', '')
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
		let g:pukiwiki_config['password'] = pass
		return 0
	else
		call s:VITAL.print_error(title)
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
	if !exists('b:pukiwiki_site_name') ||
	\	!has_key(g:pukiwiki_config, b:pukiwiki_site_name)
		return []
	endif

	" 添付ファイルの一覧
	let page = b:pukiwiki_page
	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']

	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'list'
	let enc_page = s:VITAL.iconv(page, &enc, enc)
	let param['refer'] = enc_page

	let retdic = s:PW_request('show_attach', param, enc_page, 'GET')
	if !retdic['success']
		return 0
	endif

	let body = split(retdic['content'], '\n')
	let body = filter(body, 'v:val =~ "<li><a href=\".*</a>$"')
	let body = map(body, 'substitute(v:val, "\\s*<li><a href=[^>]*>", "", "")')
	let body = map(body, 'substitute(v:val, "</a>", "", "")')
	return body
endfunction "}}}

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
			throw "指定されたファイルに誤りがあります"
		endif
	else
		let lines = ["pukiwiki.bookmark.v1."]
	endif

	call add(lines, b:pukiwiki_site_name . "," . b:pukiwiki_page)
	call writefile(lines, g:pukiwiki_bookmark)
	echo "success"
endfunction " }}}

" page open s:[top/attach/list/search] {{{
function! s:PW_get_top_page(site_name) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let top = sitedict['top']

	return s:PW_get_edit_page(a:site_name, top, 1)

endfunction "}}}

function! s:PW_show_attach(site_name, page) "{{{
"----------------------------------------------
" 添付ファイル用の画面を表示する.
" 表示せずにコマンドだけ・・・のほうがいいのかな
"----------------------------------------------

	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']

	" 添付ファイルの一覧
	let enc_page = s:VITAL.iconv(a:page, &enc, enc)
	let param = {}
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'list'
	let param['refer'] = enc_page
	let retdic = s:PW_request('show_attach', param, a:page, 'GET')
	if !retdic['success']
		return 0
	endif
	let body = retdic['content']

	let body = substitute(body, '^.*\(<div id="body">.*<hr class="full_hr" />\).*$', '\1', '')
	let body = substitute(body, '^.*<div id="body">.*<ul>\(.*\)</ul>.*<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<span class="small">.\{-}</span>\n', '', 'g')
	let body = substitute(body, ' </li>\n', '', 'g')
	let body = substitute(body, ' <li><a.\{-} title="\(.\{-}\)">\(.\{-}\)</a>', '\2\t(\1)', 'g')

	" [添付ファイルがありません] 対応
	let body = substitute(body, '<.\{-}>', '', 'g')
	let body = substitute(body, '\n\n*', '\n', 'g')

	call s:PW_newpage(a:site_name, a:page, 'attach')
	call s:PW_set_statusline(a:site_name, a:page)
	call s:PW_insert_header(a:site_name, a:page)
	execute "normal! i添付ファイル一覧 [[" . b:pukiwiki_page . "]]\n"
	execute "normal! i" . body

	call s:PW_endpage(a:site_name, a:page, 1)
endfunction "}}}

function! s:PW_show_page_list() "{{{
	let param = {}
	let param['cmd'] = 'list'
	let retdic = s:PW_request('show_page_list', param, '', 'GET')
	if !retdic['success']
		return
	endif
	let body = retdic['content']

	call s:PW_newpage(b:pukiwiki_site_name, 'cmd=list', 'pagelist')
	call s:PW_set_statusline(b:pukiwiki_site_name, b:pukiwiki_page)

	" がんばって加工
	let bodyl = split(body, "\n")
	let bodyl = filter(bodyl, 'v:val =~ "^\\s*<li><a href=" || v:val =~ "^\\s*<li><a id="')
	let bodyl = map(bodyl, 'substitute(v:val, "^\\s*<li><a href.*>\\(.*\\)</a><small>\\(.*\\)</small>.*$", "- [[\\1]]\\t\\2", "")')
	let bodyl = map(bodyl, 'substitute(v:val, "^\\s*<li><a id.*><strong>\\(.*\\)</strong></a>.*$", "\\n*** \\1", "")')
	let bodyl = map(bodyl, 's:HTML.decodeEntityReference(v:val)')
	let body = join(bodyl, "\n")

	execute "normal! i" . body

	" page 名しかないので, decode しなくても良い気がする.
	" single quote &apos;  &#xxxx などはやらないといけないらしい.

	execute ":setlocal noai"
	execute "normal! gg0"
	call s:PW_insert_header(b:pukiwiki_site_name, b:pukiwiki_page)

	call s:PW_endpage(b:pukiwiki_site_name, b:pukiwiki_page, 1)
endfunction "}}}

function! s:PW_show_search() "{{{

	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let word = input('keyword: ')
	if word == ''
		return
	endif
	let type = 'AND'
	let andor = input('(And/or): ')
	if andor =~? 'o\%[r]'
		let type = 'OR'
	endif

	let param = {}
	let param['encode_hint'] = 'ぷ'
	let param['word'] = word
	let param['type'] = type
	let param['cmd'] = 'search'
	let retdic = s:PW_request('show_search', param, '', 'POST')
	if !retdic['success']
		return
	endif

	call s:PW_newpage(b:pukiwiki_site_name, 'cmd=search', 'search')
	call s:PW_set_statusline(b:pukiwiki_site_name, b:pukiwiki_page)

	" がんばって加工
	let bodyl = split(retdic['content'], '\n')
	let bodyl = filter(bodyl, 'v:val =~ "^\\s*<li><a href=" || v:val =~ "^<strong class="')
	let bodyl = map(bodyl, 'substitute(v:val, "^\\s*<li><a href.*>\\(.*\\)</a>\\(.*\\)</li>.*$", "- [[\\1]]\\t\\2", "")')
	let bodyl[-1] = substitute(bodyl[-1], '<[^>]*>', '', 'g')
	let bodyl = map(bodyl, 's:HTML.decodeEntityReference(v:val)')
	let mes = remove(bodyl, -1)
	call insert(bodyl, mes, 0)
	let body = join(bodyl, "\n")
	unlet bodyl

	" 最終行に [... 10 ページ見つかりました] メッセージ
	" それを最初にだす
	" @REG
	execute "normal! gg0i" . body
	call s:PW_insert_header(b:pukiwiki_site_name, b:pukiwiki_page)

	call s:PW_endpage(b:pukiwiki_site_name, b:pukiwiki_page, 1)
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

function! pukiwiki#fileupload() range "{{{

	if !s:PW_is_init()
		return
	endif

	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let pass = s:get_password(sitedict)
	let enc_page = s:VITAL.iconv(b:pukiwiki_page, &enc, enc)

	let param = {}
	let param['encode_hint'] = 'ぷ'
	let param['plugin'] = 'attach'
	let param['pcmd'] = 'post'
	let param['refer'] = enc_page
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
		let retdic = s:PW_request('get_page', param, b:pukiwiki_page, 'MULT')
		if !retdic['success']
			return 0
		endif


		let body = retdic['content']
		let body = substitute(body, '^.*<h1 class="title">\(.*\)</h1>.*$', '\1', '')
		let body = substitute(body, '<a href=".*">\(.*\)</a>', '[[\1]]', '')
		call setline(linenum, curr_line . "\t" . body)

		if body =~ '.*パスワード.*'
			if has_key(sitedict, 'password')
				call remove(sitedict, 'password')
			endif
			break
		elseif body =~ '.*アップロード.*' || body =~ '.*同じファイル名.*'
			let sitedict['password'] = pass
		endif
    endfor

endfunction "}}}

" g:motion {{{
function! pukiwiki#jump_menu(pname) " {{{

	if !s:PW_is_init()
		call s:VITAL.print_error('vim-pukiwiki has not initialized')
		return
	endif

	if a:pname == 'トップ' || a:pname == 'top'
		call s:PW_get_top_page(b:pukiwiki_site_name)
	elseif a:pname == 'リロード' || a:pname == 'reload'
		if b:pukiwiki_page_type == 'attach'
			call s:PW_show_attach(b:pukiwiki_site_name, b:pukiwiki_page)
		elseif b:pukiwiki_page_type == 'pagelist'
			call s:PW_show_page_list()
		elseif b:pukiwiki_page_type == 'search'
			" @TODO 本当は検索語を覚えていて呼び出しのやり直しすべきだろう
			call s:PW_show_search()
		elseif b:pukiwiki_page == 'FormattingRules' || b:pukiwiki_page == 'RecentChanges'
			call s:PW_get_source_page(b:pukiwiki_site_name, b:pukiwiki_page)
		else
			call s:PW_get_edit_page(b:pukiwiki_site_name, b:pukiwiki_page, 0)
		endif
	elseif a:pname == '新規' || a:pname == 'new'
		let page = input('page name: ')
		if page == ''
			return
		endif
		call s:PW_get_edit_page(b:pukiwiki_site_name, page, 1)
	elseif a:pname == '一覧' || a:pname == 'list'
		call s:PW_show_page_list()
	elseif a:pname == '単語検索' || a:pname == 'search'
		call s:PW_show_search()
	elseif a:pname == '添付' || a:pname == 'attach'
		call s:PW_show_attach(b:pukiwiki_site_name, b:pukiwiki_page)
	elseif a:pname == '最終更新' || a:pname == 'recent'
		let page = 'RecentChanges'
		call s:PW_get_source_page(b:pukiwiki_site_name, page)
	elseif a:pname == 'ヘルプ' || a:pname == 'help'
		let page = 'FormattingRules'
		call s:PW_get_source_page(b:pukiwiki_site_name, page)
	endif
	return
endfunction " }}}

function! pukiwiki#jump()  "{{{
	if !s:PW_is_init()
		return
	endif
	if g:pukiwiki_show_header && line('.') < 4
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
		return
	endif

	if &modified
		call s:VITAL.print_error("No write since last change")
		return
	endif

	let cur = substitute(cur, '\[\[\(.*\)\]\]', '\1', '')
	if g:pukiwiki_show_header && line('.') <= s:pukiwiki_header_row
		return pukiwiki#jump_menu(cur)
	endif

	" InterWikiNameのエイリアスではないエイリアス
	" つまり、ただのエイリアス
	if cur =~ '>'
		let cur = substitute(cur, '^.*>\([^:]*\)$', '\1', '')
	endif

	if cur =~ ':'
		return
	endif

	call s:PW_get_edit_page(b:pukiwiki_site_name, cur, 1)
endfunction "}}}

function! pukiwiki#move_next_bracket() "{{{
	let tmp = @/
	let @/ = s:pukiwiki_bracket_name
	silent! execute "normal! n"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}

function! pukiwiki#move_prev_bracket() "{{{
	let tmp = @/
	let @/ = s:pukiwiki_bracket_name
	execute "normal! hhh"
	silent! execute "normal! N"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}
" }}}

" s:alice.vim {{{

function! s:PW_joindictstr(dict) " {{{
	let ret = ''
	for key in keys(a:dict)
		if strlen(ret) | let ret .= "&" | endif
		let ret .= key . "=" . a:dict[key]
	endfor
	return ret
endfunction " }}}

function! s:PW_urlencode(str) "{{{
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
      let result .= ch
    else
      let result .= printf("%%%02X", char2nr(ch))
    endif
  endwhile
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

"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set foldmethod=marker:

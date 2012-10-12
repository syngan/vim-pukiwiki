" vim: set ts=4 sts=4 sw=4 noet fdm=marker:
" $Id: pukiwiki.vim 13 2008-07-27 10:12:31Z ishii $

if exists('plugin_pukiwiki_disable')
	finish
endif

scriptencoding euc-jp

" global 変数

" デバッグ用
if !exists('g:pukiwiki_debug')
	let g:pukiwiki_debug = 0
endif

" http://vimwiki.net/pukivim_version を取得して
" スナップショットが更新されているかチェックする。
if !exists('g:pukiwiki_check_snapshot')
	let g:pukiwiki_check_snapshot = 1
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

let g:pukivim_dir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '')

let s:version_serial = 20080727
let s:version_url = 'http://vimwiki.net/pukivim_version'

command! PukiVim :call PukiWiki()

function! PW_buf_vars()"{{{
	" デバッグ用
	call AL_echokv('site_name' , b:site_name)
	call AL_echokv('url'       , b:url)
	call AL_echokv('enc'       , b:enc)
	call AL_echokv('top'       , b:top)
	call AL_echokv('page'      , b:page)
	call AL_echokv('digest'    , b:digest)
	call AL_echokv('original'  , b:original)
endfunction"}}}

function! PukiWiki()"{{{
	if !s:PW_init_check()
		echohl ErrorMsg 
		echo '起動に失敗しました。'
		echohl None
		return
	endif

	if !s:PW_read_pukiwiki_list()
		AL_echo('ブックマークの読み込みに失敗しました。', 'ErrorMsg')
		return
	endif

	" 最新版のチェック
	if g:pukiwiki_check_snapshot
		if s:PW_is_exist_new()
			call AL_echo('PukiVim のスナップショットが更新されています。', 'WarningMsg')
			call AL_echo('')
		endif
	endif
endfunction"}}}

function! s:PW_read_pukiwiki_list()"{{{
	if !filereadable(s:pukiwiki_list)
		return 0
	endif

	execute ":sp " . s:pukiwiki_list
	execute "set filetype=pukiwiki_list"
	runtime! ftplugin/pukiwiki_list.vim
	return 1
endfunction"}}}

function! s:PW_init_check()"{{{
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

	if !AL_mkdir(g:pukiwiki_datadir)
		AL_echo('データディレクトリーが作成できません。', 'ErrorMsg')
		return 0
	endif

	" BookMark 最初は無いからスクリプトに付属の物をユーザー用にコピーする。
	let s:pukiwiki_list = g:pukiwiki_datadir . '/pukiwiki.list'
	let s:pukiwiki_list_dist = g:pukivim_dir . '/pukiwiki.list-dist'
	if !filereadable(s:pukiwiki_list)
		if !AL_filecopy(s:pukiwiki_list_dist, s:pukiwiki_list)
			call AL_echo('pukiwiki.list-dist のコピーに失敗しました。', 'ErrorMsg')
			return 0
		endif
	endif

	return 1
endfunction"}}}

function! s:PW_is_exist_new()"{{{
	" 最新のスナップショットが有るのかチェック
	let cmd = 'curl -s ' . AL_quote(s:version_url)
	let result = system(cmd)
	if result > s:version_serial
		return 1
	endif
	return 0
endfunction"}}}

function! PW_get_edit_page(site_name, url, enc, top, page)"{{{
	let start = localtime()
	let enc_page = iconv(a:page, &enc, a:enc)
	let enc_page = AL_urlencode(enc_page)
	let cmd = a:url . "?cmd=edit&page=" . enc_page
	let tmp = tempname()
	let cmd = "curl -s -o " . tmp .' '. AL_quote(cmd)

	let result = system(cmd)
	let result = PW_fileread(tmp)
	let result = iconv(result, a:enc, &enc)

	if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
		call AL_echo('ページの読み込みに失敗しました。凍結されているか、認証が必要です。', 'WarningMsg')
		call delete(tmp)
		return
	endif
	let phase1 = localtime()

	execute ":e! ++enc=" . a:enc . ' ' . tmp
	let stmp = @/
	let @/ = '<input type="hidden" name="digest" value="'
	silent! execute "normal! n"
	let @/ = stmp
	let digest_line = getline('.')
	call delete(tmp)

	let digest = substitute(digest_line, '.*name="digest" value="\([0-9a-z]\{-}\)" />.*', '\1', '')

	let msg = substitute(result, '.*<textarea\_.\{-}>\(\_.\{-}\)</textarea>.*', '\1', '')

	let phase2 = localtime()

	execute "normal! ggdG"

	execute ":setlocal indentexpr="
	execute ":setlocal noai"
	silent! execute "normal! i" . a:site_name . " " . a:page . "\n[[トップ]] [[リロード]] [[新規]] [[一覧]] [[単語検索]] [[最終更新]] [[ヘルプ]]\n------------------------------------------------------------------------------\n"
	silent! execute "normal! i" . msg

	call AL_decode_entityreference_with_range('%')
	silent! execute ":set nomodified"
	let edit_form = tempname()
	call AL_write(edit_form)
	let phase3 = localtime()

	let prev_bufnr = bufnr('%')
	execute ":e ++enc=" . a:enc . ' ' . edit_form
	execute ":bdelete " . prev_bufnr
	execute ':setlocal nobuflisted'
	execute ":set filetype=pukiwiki_edit"
	runtime! ftplugin/pukiwiki_edit.vim
	let b:site_name = a:site_name
	let b:url       = a:url
	let b:enc       = a:enc
	let b:top       = a:top
	let b:page      = a:page
	let b:digest    = digest
	let b:original  = msg

	let status_line = b:page . ' ' . b:site_name
	let status_line = escape(status_line, ' ')
	silent! execute ":f " . status_line
	call delete(edit_form)
	execute ":setlocal noswapfile"
	silent! execute ":redraws!"
	augroup PukiWikiEdit
		execute "autocmd! BufWriteCmd " . status_line . " call PW_write()"
	augroup END

	let phase4 = localtime()
	if g:pukiwiki_debug
		echo 'start - phase1  = ' . (phase1 - start)
		echo 'phase1 - phase2 = ' . (phase2 - phase1)
		echo 'phase2 - phase3 = ' . (phase3 - phase2)
		echo 'phase3 - phase4 = ' . (phase4 - phase3)
	endif
endfunction"}}}

function! PW_write()"{{{

	let notimestamp = ''
	let last_confirm = input('タイムスタンプを変更しない。(y/N): ')
	if last_confirm =~ '^\cy'
		let notimestamp = 'true'
	endif

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.1'
		call AL_write(file)
		call AL_echo(file)
	endif

	silent! execute "normal! 1G3D"
	let cl = 1
	while cl <= line('$')
		let line = getline( cl )
		let line = iconv( line, &enc, b:enc )
		let line = AL_urlencode( line )
		call setline( cl, line )
		let cl = cl + 1
	endwhile

	if 1 < line('$')
		silent! %s/$/%0A/g
		execute ":noh"
		let @/ = ''
	endif

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.2'
		call AL_write(file)
		call AL_echo(file)
	endif

	execute ":setlocal noai"
	let cmd = "normal! 1G0iencode_hint=" . AL_urlencode( iconv( 'ぷ', &enc, b:enc ) )
	let cmd = cmd . "&cmd=edit&page=" . AL_urlencode( iconv( b:page, &enc, b:enc ) )
	let cmd = cmd . "&digest=" . b:digest . "&write=" . AL_urlencode( iconv( 'ページの更新', &enc, b:enc ) )
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
	let cmd = "curl -s -o " . result . " -d @" . post . " " . b:url
	call AL_system(cmd)
	call delete(post)

	" 成功するとPukiWikiがlocationヘッダーを吐くのでresultが作成されない。
	" 作成されている場合には何らかのエラーをHTMLで吐き出している。
	if filereadable(result)
		let body = PW_fileread(result)
		let body = iconv( body, b:enc, &enc )
		if body =~ '<title>\_.\{-}を削除しました\_.\{-}<\/title>'
			let page = b:page
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:top)
			call AL_echo(page . ' を削除しました')
			return
		endif

		" 失敗
		call delete(result)
		execute ":undo"
		execute ":set nomodified"
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
		let site_name = b:site_name
		let url       = b:url
		let enc       = b:enc
		let top       = b:top
		let page      = b:page

		" 書き込みしようとしたバッファの名前の前に'ローカル'を付けて
		" 現在のサーバー上の内容を取得して'diffthis'を実行する。
		let status_line = 'ローカル ' . page . ' ' . site_name
		execute ":f " . escape(status_line, ' ')
		execute ":diffthis"
		execute ":new"
		call PW_get_edit_page(site_name, url, enc, top, page)
		execute ":diffthis"
		call AL_echo('更新の衝突が発生したか、その他のエラーで書き込めませんでした。', 'ErrorMsg')
		return 0
	endif

	call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:page)
	call AL_echo('更新成功！')

endfunction"}}}

function! PW_fileread(filename)"{{{
	if has('win32')
		let filename=substitute(a:filename,"/","\\","g")
	else
		let filename=a:filename
	endif
	return AL_fileread(filename)
endfunction"}}}

if !exists('*AL_filecopy')"{{{
function! AL_filecopy(from, to)
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
endfunction
endif"}}}


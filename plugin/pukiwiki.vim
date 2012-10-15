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
" http://pukiwiki.sourceforge.jp/?PukiWiki%2F%E3%83%97%E3%83%A9%E3%82%B0%E3%82%A4%E3%83%B3%2F1.4



" option {{{
if exists('plugin_pukiwiki_disable')
	finish
endif

scriptencoding euc-jp

" global �ѿ�

" �ǥХå���
if !exists('g:pukiwiki_debug')
	let g:pukiwiki_debug = 0
endif

" http://vimwiki.net/pukivim_version ���������
" ���ʥåץ���åȤ���������Ƥ��뤫�����å����롣
" �ǥե���Ȥ� 0 ���ѹ�
if !exists('g:pukiwiki_check_snapshot')
	let g:pukiwiki_check_snapshot = 0
endif

" �֥å��ޡ�������¸������
" �ޥ���桼������
if !exists('g:pukiwiki_multiuser')
	let g:pukiwiki_multiuser = has('unix') && !has('macunix') ? 1 : 0
endif
" �桼���ե�����ΰ�������
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

" �����ॹ����פ��ѹ����뤫�ɤ����γ�ǧ��å�����
" 1 = ���Ĥ� yes
" 0 = ���Ĥ� no
"-1 (else) ��ǧ����
if !exists('g:pukiwiki_timestamp_update')
	let g:pukiwiki_timestamp_update = -1
endif


let g:pukivim_dir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '')

let s:version_serial = 20080727
let s:version_url = 'http://vimwiki.net/pukivim_version'


"}}}

command! -nargs=* PukiVim :call PukiWiki(<f-args>)

function! PW_buf_vars() "{{{
	" �ǥХå���
	call AL_echokv('site_name' , b:site_name)
	call AL_echokv('url'       , b:url)
	call AL_echokv('enc'       , b:enc)
	call AL_echokv('top'       , b:top)
	call AL_echokv('page'      , b:page)
	call AL_echokv('digest'    , b:digest)
	call AL_echokv('original'  , b:original)
endfunction "}}}

function! PukiWiki(...) "{{{
	if !s:PW_init_check()
		echohl ErrorMsg 
		echo '��ư�˼��Ԥ��ޤ�����'
		echohl None
		return
	endif

	if a:0 == 0 
		if !s:PW_read_pukiwiki_list()
			AL_echo('�֥å��ޡ������ɤ߹��ߤ˼��Ԥ��ޤ�����', 'ErrorMsg')
			return
		endif
	else
		if !call("s:PW_read_pukiwiki_list_witharg", a:000)
			AL_echo('�֥å��ޡ������ɤ߹��ߤ˼��Ԥ��ޤ�����', 'ErrorMsg')
			return
		endif
	endif


	" �ǿ��ǤΥ����å�
	if g:pukiwiki_check_snapshot
		if s:PW_is_exist_new()
			call AL_echo('PukiVim �Υ��ʥåץ���åȤ���������Ƥ��ޤ���', 'WarningMsg')
			call AL_echo('')
		endif
	endif
endfunction "}}}

function! s:PW_read_pukiwiki_list() "{{{
	if !filereadable(s:pukiwiki_list)
		return 0
	endif

	execute ":e " . s:pukiwiki_list
	execute "set filetype=pukiwiki_list"
"	runtime! ftplugin/pukiwiki_list.vim
	return 1
endfunction "}}}

" PukiVim [ SiteName [ PageName ]]
function! s:PW_read_pukiwiki_list_witharg(...) "{{{

	let site_name = a:1

	if !filereadable(s:pukiwiki_list)
		return 0
	endif

	for line in readfile(s:pukiwiki_list)
		if line !~ '^' . site_name . '\t\+http://.*\t\+.*$'
			continue
		endif
		let url       = substitute(line , '.*\(http.*\)\t\+.*'     , '\1' , '')
		let enc       = substitute(line , '^.*\t\+\(.*\)$'         , '\1' , '')
		let top       = substitute(url  , '.*?\([^\t]*\)\t*'       , '\1' , '')
		if a:0 > 1
			let page  = a:2
		else
			let page  = top
		endif
		let url       = substitute(url  , '^\(.*\)?.*'             , '\1' , '')
"		if &modified
"			execute ":w"
"		endif
		call PW_get_edit_page(site_name, url, enc, top, page)
		return 1
	endfor

	echohl ErrorMsg 
	echo 'site "' . site_name . '" not found.'
	echohl None
	return 0
endfunction "}}}


function! s:PW_init_check() "{{{
	" alice.vim�Υ��ɤ�μ¤ˤ���
	if !exists('*AL_version')
		runtime! plugin/alice.vim
	endif

	" alice.vim ��̵ͭ������å�
	if !exists('*AL_version')
		echohl ErrorMsg
		echo 'alice.vim �����ɤ���Ƥ��ޤ���'
		echohl None
		return 0
	endif

	" curl ��̵ͭ������å�
	let curl = 'curl'
	if has('win32')
		let curl = 'curl.exe'
	endif
	if curl != AL_hascmd('curl')
		call AL_echo('curl �����Ĥ���ޤ���', 'ErrorMsg')
		return 0
	endif

	if !AL_mkdir(g:pukiwiki_datadir)
		AL_echo('�ǡ����ǥ��쥯�ȥ꡼�������Ǥ��ޤ���', 'ErrorMsg')
		return 0
	endif

	" BookMark �ǽ��̵�����饹����ץȤ���°��ʪ��桼�����Ѥ˥��ԡ����롣
	let s:pukiwiki_list = g:pukiwiki_datadir . '/pukiwiki.list'
	let s:pukiwiki_list_dist = g:pukivim_dir . '/pukiwiki.list-dist'
	if !filereadable(s:pukiwiki_list)
		if !AL_filecopy(s:pukiwiki_list_dist, s:pukiwiki_list)
			call AL_echo('pukiwiki.list-dist �Υ��ԡ��˼��Ԥ��ޤ�����', 'ErrorMsg')
			return 0
		endif
	endif

	return 1
endfunction "}}}

function! s:PW_is_exist_new() "{{{
	" �ǿ��Υ��ʥåץ���åȤ�ͭ��Τ������å�
	" snapshot �Ȥ�... pukivim �ΥС�������ֹ�Τ���
	let cmd = 'curl -s ' . AL_quote(s:version_url)
	let result = system(cmd)
	if result > s:version_serial
		return 1
	endif
	return 0
endfunction "}}}


" edit �ڡ����򳫤�
function! PW_get_edit_page(site_name, url, enc, top, page) "{{{
	return PW_get_page(a:site_name, a:url, a:enc, a:top, a:page, "edit")
endfunction "}}}

function! PW_get_source_page(site_name, url, enc, top, page) "{{{
	return PW_get_page(a:site_name, a:url, a:enc, a:top, a:page, "source")
endfunction "}}}

" �ڡ����򳫤�
" pwcmd = "edit" or "source"
function! PW_get_page(site_name, url, enc, top, page, pwcmd) "{{{
	let start = localtime()
	let enc_page = iconv(a:page, &enc, a:enc)
	let enc_page = PW_urlencode(enc_page)
	let cmd = a:url . "?cmd=" . a:pwcmd . "&page=" . enc_page
	let tmp = tempname()
	let cmd = "curl -s -o " . tmp .' '. AL_quote(cmd)

	let result = system(cmd)
	let result = PW_fileread(tmp)
	let result = iconv(result, a:enc, &enc)

	if a:pwcmd == 'edit' 
		if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
			if g:pukiwiki_debug
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���' . cmd, 'WarningMsg')
			else
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���', 'WarningMsg')
			endif
			call delete(tmp)
			return
		endif
	elseif a:pwcmd == 'source'
		if result !~ '<pre id="source">'
			if g:pukiwiki_debug
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�����ǧ�ڤ�ɬ�פǤ���' . cmd, 'WarningMsg')
			else
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�����ǧ�ڤ�ɬ�פǤ���', 'WarningMsg')
			endif
			call delete(tmp)
			return
		endif

	else
		call AL_echo('unknown command: ' . a:pwcmd, 'WarningMsg')
		call delete(tmp)
		return
	endif


	let phase1 = localtime()

	if a:pwcmd == 'edit' 
		" digest ��ʬ�� grep 
		execute ":e! ++enc=" . a:enc . ' ' . tmp
		let stmp = @/
		let @/ = '<input type="hidden" name="digest" value="'
		silent! execute "normal! n"
		let @/ = stmp
		let digest_line = getline('.')

		let digest = substitute(digest_line, '.*name="digest" value="\([0-9a-z]\{-}\)" />.*', '\1', '')

		let msg = substitute(result, '.*<textarea\_.\{-}>\(\_.\{-}\)</textarea>.*', '\1', '')
	else
		" cmd='source'
		execute ":e! ++enc=" . a:enc . ' ' . tmp
		let digest = ''
		let msg = substitute(result, '.*<pre id="source">\(\_.\{-}\)</pre>.*', '\1', '')
	endif

	call delete(tmp)
	let phase2 = localtime()

	" ���õ�
	execute "normal! ggdG"

	" �إå��ιԿ����ѹ�������ˤ�, 
	" PW_write �ˤ�ƶ�����
	let pp = &paste
	execute ":setlocal indentexpr="
	execute ":setlocal noai"
	execute ":setlocal paste"
	silent! execute "normal! i" . a:site_name . " " . a:page . "\n"
				\ . "[[�ȥå�]] [[ź��]] [[�����]] [[����]] [[����]] [[ñ�측��]] [[�ǽ�����]] [[�إ��]]\n"
				\ . "------------------------------------------------------------------------------\n"
	silent! execute "normal! i" . msg

	call AL_decode_entityreference_with_range('%')
	silent! execute ":set nomodified"
	let edit_form = tempname()
	call AL_write(edit_form)
	let phase3 = localtime()

	let prev_bufnr = bufnr('%')
	execute ":e ++enc=" . a:enc . ' ' . edit_form
	if bufexists(prev_bufnr)
		execute ":bdelete " . prev_bufnr
	endif
	execute ':setlocal nobuflisted'
	execute ":set filetype=pukiwiki_edit"
"	runtime! ftplugin/pukiwiki_edit.vim
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
	if a:pwcmd == 'edit'
		augroup PukiWikiEdit
			execute "autocmd! BufWriteCmd " . status_line . " call PW_write()"
		augroup END
	endif
	if a:pwcmd == 'source'
		execute ':setlocal readonly'
		execute ":setlocal nomodifiable"
	endif

	if g:pukiwiki_debug
		let phase4 = localtime()
		echo 'start - phase1  = ' . (phase1 - start)
		echo 'phase1 - phase2 = ' . (phase2 - phase1)
		echo 'phase2 - phase3 = ' . (phase3 - phase2)
		echo 'phase3 - phase4 = ' . (phase4 - phase3)
	endif

	if ! pp
		execute ":setlocal nopaste"
	endif

endfunction "}}}




" �ڡ����򳫤�
" pwcmd = "edit" or "source"
function! PW_get_page2(site_name, url, enc, top, page, pwcmd) "{{{
	let start = localtime()
	let enc_page = iconv(a:page, &enc, a:enc)
	let enc_page = PW_urlencode(enc_page)
	let cmd = a:url . "?cmd=" . a:pwcmd . "&page=" . enc_page
	let tmp = tempname()
	let cmd = "curl -s -o " . tmp .' '. AL_quote(cmd)

	let result = system(cmd)
	let result = PW_fileread(tmp)
	let result = iconv(result, a:enc, &enc)


	let phase1 = localtime()

	if a:pwcmd == 'edit' 
		if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
			if g:pukiwiki_debug
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���' . cmd, 'WarningMsg')
			else
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���', 'WarningMsg')
			endif
			call delete(tmp)
			return
		endif


		" digest ��ʬ�� grep 
		execute ":e! ++enc=" . a:enc . ' ' . tmp
		let stmp = @/
		let @/ = '<input type="hidden" name="digest" value="'
		silent! execute "normal! n"
		let @/ = stmp
		let digest_line = getline('.')
		call delete(tmp)

		let digest = substitute(digest_line, '.*name="digest" value="\([0-9a-z]\{-}\)" />.*', '\1', '')
		let msg = substitute(result, '.*<textarea\_.\{-}>\(\_.\{-}\)</textarea>.*', '\1', '')

	elseif a:pwcmd == 'source'
		if result !~ '<pre id="source">'
			if g:pukiwiki_debug
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���' . cmd, 'WarningMsg')
			else
				call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���', 'WarningMsg')
			endif
			call delete(tmp)
			return
		endif

		call delete(tmp)

		let digest = ''
		let msg = substitute(result, '.*<pre id="source">\(\_.\{-}\)</pre>.*', '\1', '')

	else
		call AL_echo('unknown command: ' . a:pwcmd, 'WarningMsg')
		call delete(tmp)
		return
	endif

	let phase2 = localtime()

	" ���õ�
	execute "normal! ggdG"

	" �إå��ιԿ����ѹ�������ˤ�, 
	" PW_write �ˤ�ƶ�����
	let pp = &paste
	execute ":setlocal indentexpr="
	execute ":setlocal noautoindent"
	execute ":setlocal paste"
	silent! execute "normal! i" . a:site_name . " " . a:page . "\n"
				\ . "[[�ȥå�]] [[�����]] [[����]] [[����]] [[ñ�측��]] [[�ǽ�����]] [[�إ��]]\n"
				\ . "------------------------------------------------------------------------------\n"
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
"	runtime! ftplugin/pukiwiki_edit.vim
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
	if a:pwcmd == 'source'
		execute ':setlocal readonly'
	endif
	silent! execute ":redraws!"
	if a:pwcmd == 'edit'
		augroup PukiWikiEdit
			execute "autocmd! BufWriteCmd " . status_line . " call PW_write()"
		augroup END
	endif

	let phase4 = localtime()
	if g:pukiwiki_debug
		echo 'start - phase1  = ' . (phase1 - start)
		echo 'phase1 - phase2 = ' . (phase2 - phase1)
		echo 'phase2 - phase3 = ' . (phase3 - phase2)
		echo 'phase3 - phase4 = ' . (phase4 - phase3)
	endif

	if ! pp
		execute ":setlocal nopaste"
	endif

endfunction "}}}

function! PW_write() "{{{

	if ! &modified
		return
	endif

	let notimestamp = ''
	let lineno = line('.')

	if g:pukiwiki_timestamp_update == 1
	  let notimestamp = ''
	elseif g:pukiwiki_timestamp_update == 0
		let notimestamp = 'true'
	else
		let last_confirm = input('�����ॹ����פ��ѹ����ʤ���(y/N): ')
		if last_confirm =~ '^\cy'
			let notimestamp = 'true'
		endif
	endif

	if g:pukiwiki_debug
		let file = g:pukiwiki_datadir . '/pukiwiki.1'
		call AL_write(file)
		call AL_echo(file)
	endif

	" �إå��κ��. �桼�����إå����������
	" �񤭹��ߤ���������ʻ���
	silent! execute "normal! 1G3D"
	let cl = 1
	execute ":setlocal fenc="
	while cl <= line('$')
		let line = getline(cl)
		let line = iconv(line, &enc, b:enc)
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
	let cmd = "normal! 1G0iencode_hint=" . PW_urlencode( iconv( '��', &enc, b:enc ) )
	let cmd = cmd . "&cmd=edit&page=" . PW_urlencode( iconv( b:page, &enc, b:enc ) )
	let cmd = cmd . "&digest=" . b:digest . "&write=" . PW_urlencode( iconv( '�ڡ����ι���', &enc, b:enc ) )
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
	let cmd = "curl -s -o " . result . " -d @" . post . ' "' . b:url . '"'
	call AL_system(cmd)

	if ! g:pukiwiki_debug
		call delete(post)
	elseif ! filereadable(result)
		call delete(post)
	endif

	" ���������PukiWiki��location�إå������Ǥ��Τ�result����������ʤ���
	" ��������Ƥ�����ˤϲ��餫�Υ��顼��HTML���Ǥ��Ф��Ƥ��롣
	if filereadable(result)
		let body = PW_fileread(result)
		let body = iconv( body, b:enc, &enc )
		if body =~ '<title>\_.\{-}�������ޤ���\_.\{-}<\/title>'
			let page = b:page
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:top)
			call AL_echo(page . ' �������ޤ���')
			return
		endif

		" ����
		execute ":undo"
		execute ":set nomodified"
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
		let site_name = b:site_name
		let url       = b:url
		let enc       = b:enc
		let top       = b:top
		let page      = b:page

		" �񤭹��ߤ��褦�Ȥ����Хåե���̾��������'������'���դ���
		" ���ߤΥ����С�������Ƥ��������'diffthis'��¹Ԥ��롣
		let status_line = '������ ' . page . ' ' . site_name
		execute ":f " . escape(status_line, ' ')
		execute ":diffthis"
		execute ":new"

		call PW_get_edit_page(site_name, url, enc, top, page)
		execute ":diffthis"
		if g:pukiwiki_debug
			echo "digest=[" . b:digest . "] cmd=[" . cmd . "]"
			echo "&enc=" . &enc . ", enc=" . b:enc . ", page=" . b:page
			echo "iconv=" . Byte2hex(iconv(b:page, &enc, b:enc))
			echo "urlen=" . PW_urlencode( iconv( b:page, &enc, b:enc ) )
			call AL_echo('�����ξ��ͤ�ȯ��������������¾�Υ��顼�ǽ񤭹���ޤ���Ǥ�����' . result, 'ErrorMsg')
		else
			call AL_echo('�����ξ��ͤ�ȯ��������������¾�Υ��顼�ǽ񤭹���ޤ���Ǥ�����', 'ErrorMsg')
			call delete(result)
		endif
		return 0
	endif

	call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:page)

	" �������Ԥ˰�ư
	execute "normal! " . lineno . "G"
	if g:pukiwiki_debug
		" ��󤦤äȡ������Τ� debug �Ѥ�
		call AL_echo('����������')
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
" 1) [._-] �Ϥ��Τޤ�
" 2) [A-Za-z0-9] �⤽�Τޤޡ�
" 3) 0x20[ ] ==> 0x2B[+]
"    �ʾ��3�Ĥε�§�����ƤϤޤ�ʤ�ʸ���ϡ� ���ơ� "%16�ʿ�ɽ��"���Ѵ����롣
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




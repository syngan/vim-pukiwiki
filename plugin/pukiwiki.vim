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
" global �ѿ�
"---------------------------------------------

" �ǥХå���
if !exists('g:pukiwiki_debug')
	let g:pukiwiki_debug = 0
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

"}}}

command! -nargs=* PukiWiki :call PukiWiki(<f-args>)

" variables {{{
let s:pukiwiki_history = []

let s:pukivim_ro_menu = "\n"
	\ . "[[�ȥå�]] [[ź��]] [[�����]] [[����]] [[����]] [[ñ�측��]] [[�ǽ�����]] [[�إ��]]\n"
	\ . "------------------------------------------------------------------------------\n"
"let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:bracket_name = '\[\[\_.\{-}\]\]'

" }}}

" vital.vim {{{
"let s:VITAL = vital#of('vim-pukiwiki')
"let s:HTTP = s:VITAL.import('Web.Http')
" }}}

function! s:PW_newpage(site_name, page) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let enc = sitedict['encode']

	execute ":e! ++enc=" . enc . " " . tempname()
	execute ":setlocal modifiable"
	execute ":setlocal indentexpr="
	execute ":setlocal noautoindent"
	execute ":setlocal paste"
	execute ':setlocal nobuflisted'

	execute ":setlocal filetype=pukiwiki"

	" nnoremap {{{
	nnoremap <silent> <buffer> <CR>    :call PW_move()<CR>
	nnoremap <silent> <buffer> <TAB>   :call PW_bracket_move()<CR>
	nnoremap <silent> <buffer> <S-TAB> :call PW_bracket_move_rev()<CR>
	"nnoremap <silent> <buffer> B       :call PW_get_last_page()<CR>
	" }}}

	let b:site_name = a:site_name
	let b:page      = a:page
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
	silent! execute ":redraws!"
endfunction "}}}

function! s:PW_set_statusline(site_name, page) "{{{
"	let status_line = a:page . ' ' . a:site_name
	let status_line = a:page
	let status_line = escape(status_line, ' ')
	silent! execute ":f " . status_line
	return status_line
endfunction "}}}

function! PW_buf_vars() "{{{
	" �ǥХå���
	if exists('b:sitename')
		call AL_echokv('site_name' , b:site_name)
		let sitedict = g:pukiwiki_config[a:site_name]
		call AL_echokv('url' , sitedict['url'])
		call AL_echokv('top' , sitedict['top'])
		call AL_echokv('enc' , sitedict['encode'])
	else
		call AL_echokv('site_name' , 'undefined')
	endif
	if exists('b:page')
		call AL_echokv('page'      , b:page)
	else
		call AL_echokv('page'      , 'undefined')
	endif
	if exists('b:digest')
		call AL_echokv('digest'    , b:digest)
	else
		call AL_echokv('digest'    , 'undefined')
	endif



endfunction "}}}

function! s:PW_get_digest(str) "{{{
	" [[�Խ�]] ���̤��� digest ���������
	let s = matchstr(a:str,
	\     '<input type="hidden" name="digest" value="\zs.\{-}\ze" />')
	return s
endfunction "}}}

function! PukiWiki(...) "{{{
	if !s:PW_init_check()
		echohl ErrorMsg 
		echo '��ư�˼��Ԥ��ޤ�����'
		echohl None
		return
	endif

	if !call("s:PW_read_pukiwiki_list", a:000)
"		AL_echo('�֥å��ޡ������ɤ߹��ߤ˼��Ԥ��ޤ�����', 'ErrorMsg')
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
		" �䤤��碌
		let site_name = input('������̾: ')
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

	" �ǽ�˰��٤������ե�����򳫤�
	if page == 'RecentChanges'
		call s:PW_get_source_page(site_name, page)
	else
		call s:PW_get_edit_page(site_name, page, 1)
	endif
	return 1

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

"	if !AL_mkdir(g:pukiwiki_datadir)
"		AL_echo('�ǡ����ǥ��쥯�ȥ꡼�������Ǥ��ޤ���', 'ErrorMsg')
"		return 0
"	endif

	" BookMark �ǽ��̵�����饹����ץȤ���°��ʪ��桼�����Ѥ˥��ԡ����롣
"	let s:pukiwiki_list = g:pukiwiki_datadir . '/pukiwiki.list'
"	let pukivim_dir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '')
"	let s:pukiwiki_list_dist = pukivim_dir . '/pukiwiki.list-dist'
"	if !filereadable(s:pukiwiki_list)
"		if !s:AL_filecopy(s:pukiwiki_list_dist, s:pukiwiki_list)
"			call AL_echo('pukiwiki.list-dist �Υ��ԡ��˼��Ԥ��ޤ�����', 'ErrorMsg')
"			return 0
"		endif
"	endif

	return 1
endfunction "}}}

function! s:PW_get_top_page(site_name) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let top = sitedict['top']

	return s:PW_get_edit_page(a:site_name, top, 1)

endfunction "}}}

function! s:PW_get_edit_page(site_name, page, opennew) "{{{
" edit �ڡ����򳫤�
	return s:PW_get_page(a:site_name, a:page, "edit", a:opennew)
endfunction "}}}

function! s:PW_get_source_page(site_name, page) "{{{
	return s:PW_get_page(a:site_name, a:page, "source", 1)
endfunction "}}}

function! s:PW_get_page(site_name, page, pwcmd, opennew) "{{{
" �ڡ����򳫤�
" pwcmd = "edit" or "source"
	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']
	let start = localtime()
	let enc_page = iconv(a:page, &enc, enc)
	let enc_page = s:PW_urlencode(enc_page)
"	let enc_page = s:HTTP.escape(enc_page)
	" ����� utf-8 ���Ѵ�����뤫��Ĥ����ʤ�.
	let cmd = url . "?cmd=" . a:pwcmd . "&page=" . enc_page
	let tmp = tempname()
	if 1
		let cmd = "curl -s -o " . tmp .' '. AL_quote(cmd)
		let ret = AL_system(cmd)
		let result = s:PW_fileread(tmp)
		call delete(tmp)
	else
"		let result = s:HTTP.get(cmd)
	endif

	let result = iconv(result, enc, &enc)

	if a:pwcmd == 'edit' 
		if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
"			call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�������뤵��Ƥ��뤫��ǧ�ڤ�ɬ�פǤ���', 'WarningMsg')
			return s:PW_get_source_page(a:site_name, a:page)
		endif
	elseif a:pwcmd == 'source'
		if result !~ '<pre id="source">'
			call AL_echo('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�����ǧ�ڤ�ɬ�פǤ���', 'WarningMsg')
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

	" ���õ�
	if a:opennew
		call s:PW_newpage(a:site_name, a:page)
	else
		" @REG
		let regbak = @"
		execute 'normal! ggdG'
		let @" = regbak
	endif

	silent! execute "normal! i" . a:site_name . " " . a:page . s:pukivim_ro_menu
"	silent! execute "normal! ihistory>>>>>" . len(s:pukiwiki_history) . "\n" 
"	for elm in s:pukiwiki_history
"		silent! execute "normal! i" . elm[4] . "\n"
"	endfor
"	silent! execute "normal! ihistory<<<<<" . len(s:pukiwiki_history) . "\n" 
	silent! execute "normal! i" . msg

	call AL_decode_entityreference_with_range('%')
	let phase3 = localtime()

	let b:digest    = digest

	let status_line = s:PW_set_statusline(b:site_name, b:page)
	if a:pwcmd == 'edit'
		augroup PukiWikiEdit
			execute "autocmd! BufWriteCmd " . status_line . " call s:PW_write()"
		augroup END
		call s:PW_endpage(a:site_name, a:page, 0)
	endif
	if a:pwcmd == 'source'
		call s:PW_endpage(a:site_name, a:page, 1)
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

function! PW_move()  "{{{
	if !exists('b:site_name')
		return 
	endif
	if line('.') < 4
		" �إå���ʬ
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
		call AL_echo('�ѹ�����¸����Ƥ��ޤ���', 'ErrorMsg')
		return
	endif

	let cur = substitute(cur, '\[\[\(.*\)\]\]', '\1', '')
	if line('.') < 4
		if cur == '�ȥå�'
			call s:PW_get_top_page(b:site_name)
		elseif cur == '�����'
			if b:page == 'FormattingRules' || b:page == 'RecentChanges'
				call s:PW_get_source_page(b:site_name, b:page)
			else
				call s:PW_get_edit_page(b:site_name, b:page, 0)
			endif
		elseif cur == '����'
			let page = input('�����ڡ���̾: ')
			if page == ''
				return
			endif
			call s:PW_get_edit_page(b:site_name, page, 1)
		elseif cur == '����'
			call s:PW_show_page_list()
		elseif cur == 'ñ�측��'
			call s:PW_show_search()
		elseif cur == 'ź��'
			call s:PW_show_attach(b:site_name, b:page)
		elseif cur == '�ǽ�����'
			let page = 'RecentChanges'
			call s:PW_get_source_page(b:site_name, page)
		elseif cur == '�إ��'
			call s:PW_get_source_page(b:site_name, 'FormattingRules')
		endif
		return
	endif

	" InterWikiName�Υ����ꥢ���ǤϤʤ������ꥢ��
	" �Ĥޤꡢ�����Υ����ꥢ��
	if cur =~ '>'
		let cur = substitute(cur, '^.*>\([^:]*\)$', '\1', '')
	endif

	if cur =~ ':'
		return
	endif

	call s:PW_get_edit_page(b:site_name, cur, 1)
endfunction "}}}

function! PW_bracket_move() "{{{
	let tmp = @/
	let @/ = s:bracket_name
	silent! execute "normal! n"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}

function! PW_bracket_move_rev() "{{{
	let tmp = @/
	let @/ = s:bracket_name
	execute "normal! hhh"
	silent! execute "normal! N"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}

function! s:PW_show_attach(site_name, page) "{{{
"----------------------------------------------
" ź�եե������Ѥβ��̤�ɽ������.
" ɽ�������˥��ޥ�ɤ����������Τۤ��������Τ���
"----------------------------------------------

	let sitedict = g:pukiwiki_config[a:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']


	" ź�եե�����ΰ���
	let enc_page = iconv(a:page, &enc, enc)
	let enc_page = s:PW_urlencode(enc_page)
	let url = url . '?plugin=attach&pcmd=list&refer=' . enc_page
	
	let tmp = tempname()
	
	let cmd = "curl -s -o " . tmp .' "'. url . '"'
	let result = AL_system(cmd)

	let body = s:PW_fileread(tmp)
	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*\(<div id="body">.*<hr class="full_hr" />\).*$', '\1', '')
	let body = substitute(body, '^.*<div id="body">.*<ul>\(.*\)</ul>.*<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<span class="small">.\{-}</span>\n', '', 'g')
	let body = substitute(body, ' </li>\n', '', 'g')
	let body = substitute(body, ' <li><a.\{-} title="\(.\{-}\)">\(.\{-}\)</a>', '\2\t(\1)', 'g')

	" [ź�եե����뤬����ޤ���] �б�
	let body = substitute(body, '<.\{-}>', '', 'g')
	let body = substitute(body, '\n\n*', '\n', 'g')

	call s:PW_newpage(a:site_name, a:page)
	call s:PW_set_statusline(a:site_name, a:page)

	execute "normal! i" . a:site_name . " " . b:page . s:pukivim_ro_menu 
	execute "normal! iź�եե�������� [[" . b:page . "]]\n"
	execute "normal! i" . body

	call s:PW_endpage(a:site_name, a:page, 1)
endfunction "}}}

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

	call s:PW_newpage(b:site_name, 'cmd=list')
	call s:PW_set_statusline(b:site_name, b:page)

	let body = s:PW_fileread(result)
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

	" ����ФäƲù�
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

	call s:PW_endpage(b:site_name, b:page, 1)
endfunction "}}}

function! s:PW_show_search() "{{{

	let sitedict = g:pukiwiki_config[b:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let word = input('�������: ')
	if word == ''
		return
	endif
	let type = 'AND'
	let andor = input('(And/or): ')
	if andor =~ '^\co'
		let type = 'OR'
	endif

	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' -d encode_hint=' . s:PW_urlencode('��')
	let cmd = cmd . ' -d word=' . s:PW_urlencode(word)
	let cmd = cmd . ' -d type=' . type . ' -d cmd=search ' . url
	call AL_system(cmd)

	call s:PW_newpage(b:site_name, 'cmd=search')
	call s:PW_set_statusline(b:site_name, b:page)

	let body = s:PW_fileread(result)
	call delete(result)

	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '\(.*\)<form action.*', '\1', '')
"	let body = substitute(body, '^<div class=[^\n]\{-}$', '', '')
	execute "normal! i" . body

	" ����ФäƲù�
	" @REG
	let regbak = @"
	silent! %g/<div/d
	silent! %g/<ul/d
	silent! %g/<\/ul/d
	silent! %s/<strong class="word.">//g
	silent! %s/<\/strong>//g
	silent! %s/<strong>//g
	silent! %s/^.*<li><a.*>\(.*\)<\/a>\(.*\)<\/li>$/\t\[\[\1\]\] \2/

	" �ǽ��Ԥ� [... 10 �ڡ������Ĥ���ޤ���] ��å�����
	" �����ǽ�ˤ���
	" @REG
	execute "normal! GddggP0i" . b:site_name . " " . b:page . s:pukivim_ro_menu
	let @" = regbak

	call s:PW_endpage(b:site_name, b:page, 1)
endfunction "}}}

function! PW_fileupload() range "{{{

	let sitedict = g:pukiwiki_config[b:site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let pass = input('�ѥ����: ')

	let enc_page = iconv(b:page, &enc, enc)
	let enc_page = s:PW_urlencode(enc_page)

	let tmpfile = tempname()
	let cmd = 'curl -s -o ' . tmpfile . ' -F encode_hint=' . s:PW_urlencode('��')
	let cmd = cmd . ' -F plugin=attach'
	let cmd = cmd . ' -F pcmd=post'
	let cmd = cmd . ' -F refer=' . enc_page
	let cmd = cmd . ' -F pass=' . pass 

    for linenum in range(a:firstline, a:lastline)
        "Replace loose ampersands (as in DeAmperfy())...
        let curr_line   = getline(linenum)

		" �����Ĥ���ʬ�ǥ����å����뤫.
		" file ���ɤ�뤫. directory �Ǥʤ���.
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

		let body = s:PW_fileread(tmpfile)
		let body = iconv(body, enc, &enc)
		let body = substitute(body, '^.*<h1 class="title">\(.*\)</h1>.*$', '\1', '')
		let body = substitute(body, '<a href=".*">\(.*\)</a>', '[[\1]]', '')
		call setline(linenum, curr_line . "\t" . body)
    endfor

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
	" @REG
	let regbak = @"
	silent! execute "normal! gg3D"
	let @" = regbak
	let cl = 1
	execute ":setlocal fenc="
	while cl <= line('$')
		let line = getline(cl)
		let line = iconv(line, &enc, enc)
		let line = s:PW_urlencode(line)
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
	let cmd = "normal! 1G0iencode_hint=" . s:PW_urlencode( iconv( '��', &enc, enc ) )
	let cmd = cmd . "&cmd=edit&page=" . s:PW_urlencode( iconv( b:page, &enc, enc ) )
	let cmd = cmd . "&digest=" . b:digest . "&write=" . s:PW_urlencode( iconv( '�ڡ����ι���', &enc, enc ) )
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

	" ���������PukiWiki��location�إå������Ǥ��Τ�result����������ʤ���
	" ��������Ƥ�����ˤϲ��餫�Υ��顼��HTML���Ǥ��Ф��Ƥ��롣
	if filereadable(result)
		let body = s:PW_fileread(result)
		let body = iconv( body, enc, &enc )
		if body =~ '<title>\_.\{-}�������ޤ���\_.\{-}<\/title>'
			let page = b:page
			call s:PW_get_edit_page(b:site_name, top, 0)
			call AL_echo(page . ' �������ޤ���')
			return
		endif

		" ����
		execute ":undo"
		execute ":set nomodified"
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
		let site_name = b:site_name
		let page      = b:page

		" �񤭹��ߤ��褦�Ȥ����Хåե���̾��������'������'���դ���
		" ���ߤΥ����С�������Ƥ��������'diffthis'��¹Ԥ��롣
		call s:PW_set_statusline(b:site_name, '������ ' . b:page)
		execute ":diffthis"
		execute ":new"

		call s:PW_get_edit_page(site_name, page, 0)
		execute ":diffthis"
		if g:pukiwiki_debug
			echo "digest=[" . b:digest . "] cmd=[" . cmd . "]"
			echo "&enc=" . &enc . ", enc=" . enc . ", page=" . b:page
			echo "iconv=" . Byte2hex(iconv(b:page, &enc, enc))
			echo "urlen=" . s:PW_urlencode( iconv( b:page, &enc, enc ) )
			call AL_echo('�����ξ��ͤ�ȯ��������������¾�Υ��顼�ǽ񤭹���ޤ���Ǥ�����' . result, 'ErrorMsg')
		else
			call AL_echo('�����ξ��ͤ�ȯ��������������¾�Υ��顼�ǽ񤭹���ޤ���Ǥ�����', 'ErrorMsg')
			call delete(result)
		endif
		return 0
	endif

	call s:PW_get_edit_page(b:site_name, b:page, 0)

	" �������Ԥ˰�ư
	execute "normal! " . lineno . "G"
"	silent! echo 'update ' . b:page
	if g:pukiwiki_debug
		" ��󤦤äȡ������Τ� debug �Ѥ�
		call AL_echo('����������')
	endif


endfunction "}}}

" alice.vim {{{

function! s:PW_fileread(filename) "{{{
	if has('win32')
		let filename=substitute(a:filename,"/","\\","g")
	else
		let filename=a:filename
	endif
	return AL_fileread(filename)
endfunction "}}}

function! s:AL_filecopy(from, to) "{{{
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

function! s:PW_urlencode(str) "{{{
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

"}}}

" vim:set foldmethod=marker:

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

scriptencoding euc-jp

"---------------------------------------------
" global �ѿ�
"---------------------------------------------

" �ǥХå���
if !exists('g:pukiwiki_debug')
	let g:pukiwiki_debug = 0
endif

" �����ॹ����פ��ѹ����뤫�ɤ����γ�ǧ��å�����
" 1 = ���Ĥ� yes
" 0 = ���Ĥ� no
"-1 (else) ��ǧ����
if !exists('g:pukiwiki_timestamp_update')
	let g:pukiwiki_timestamp_update = -1
endif

"}}}

" variables {{{
let s:pukiwiki_history = []

let s:pukivim_ro_menu = "\n"
	\ . "[[�ȥå�]] [[ź��]] [[�������]] [[����]] [[����]] [[ñ�측��]] [[�ǽ�����]] [[�إ��]]\n"
	\ . "------------------------------------------------------------------------------\n"
"let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:bracket_name = '\[\[\_.\{-}\]\]'

" }}}

" vital.vim {{{
let s:VITAL = vital#of('vim-pukiwiki')
let s:HTML = s:VITAL.import('Web.Html')
"let s:HTTP = s:VITAL.import('Web.Http')
" }}}

" debug {{{
function! pukiwiki#buf_vars() "{{{
	" �ǥХå���
	if exists('b:pukiwiki_sitename')
		call s:PW_echokv('site_name' , b:pukiwiki_site_name)
		let sitedict = g:pukiwiki_config[a:site_name]
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
	if !s:PW_init_check()
		echohl ErrorMsg 
		echo '��ư�˼��Ԥ��ޤ�����'
		echohl None
		return
	endif

	return s:PW_read_pukiwiki_list(a:000)
endfunction "}}}

function! s:PW_read_pukiwiki_list(...) "{{{
" bookmark
" PukiVim [ SiteName [ PageName ]]
"
	if &modified
		call s:VITAL.print_error('�ѹ�����¸����Ƥ��ޤ���')
		return
	endif

	if !exists('g:pukiwiki_config')
		call s:VITAL.print_error('g:pukiwiki_config does not defined.')
		return 0
	endif

	if !s:VITAL.is_dict(g:pukiwiki_config)
		call s:VITAL.print_error('g:pukiwiki_config is not a dictionary.')
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
			call s:VITAL.print_error('site "' . site_name . '" not found.')
			return 0
		endif
	catch /^Vim\%((\a\+)\)\?:E715/
		return 0
	endtry
	
	let dict = g:pukiwiki_config[site_name]
	if (!has_key(dict, 'url'))
		call s:VITAL.print_error('"url" does not defined.')
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

	" curl ��̵ͭ������å�
	if !executable('curl')
		call s:VITAL.print_error('curl �����Ĥ���ޤ���')
		return 0
	endif

	return 1
endfunction "}}}

function! s:PW_newpage(site_name, page) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let enc = sitedict['encode']

	execute ":e ++enc=" . enc . " " . tempname()
	execute ":setlocal modifiable"
	execute ":setlocal indentexpr="
	execute ":setlocal noautoindent"
	execute ":setlocal paste"
	execute ':setlocal nobuflisted'

	execute ":setlocal filetype=pukiwiki"

	" nnoremap {{{
	nnoremap <silent> <buffer> <CR>    :call pukiwiki#jump()<CR>
	nnoremap <silent> <buffer> <TAB>   :call pukiwiki#move_next_bracket()<CR>
	nnoremap <silent> <buffer> <S-TAB> :call pukiwiki#move_prev_bracket()<CR>
	"nnoremap <silent> <buffer> B       :call pukiwiki#get_last_page()<CR>
	" }}}

	let b:pukiwiki_site_name = a:site_name
	let b:pukiwiki_page      = a:page
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

function! s:PW_get_digest(str) "{{{
	" [[�Խ�]] ���̤��� digest ���������
	let s = matchstr(a:str,
	\     '<input type="hidden" name="digest" value="\zs.\{-}\ze" />')
	return s
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
		let cmd = "curl -s -o " . tmp .' "'. (cmd) . '"'
"		let ret = s:PW_system(cmd)
		let ret = s:PW_system(cmd)
		let result = s:PW_fileread(tmp)
		call delete(tmp)
	else
"		let result = s:HTTP.get(cmd)
	endif

	let result = iconv(result, enc, &enc)

	if a:pwcmd == 'edit' 
		if result !~ '<textarea\_.\{-}>\_.\{-}</textarea>\_.\{-}<textarea'
			return s:PW_get_source_page(a:site_name, a:page)
		endif
	elseif a:pwcmd == 'source'
		if result !~ '<pre id="source">'
			call s:VITAL.print_error('�ڡ������ɤ߹��ߤ˼��Ԥ��ޤ�����ǧ�ڤ�ɬ�פǤ���')
			return
		endif

	else
		call s:VITAL.print_error('unknown command: ' . a:pwcmd)
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

	let msg = s:HTML.decodeEntityReference(msg)
	silent! execute "normal! i" . msg

	let phase3 = localtime()

	let b:pukiwiki_digest    = digest

	let status_line = s:PW_set_statusline(b:pukiwiki_site_name, b:pukiwiki_page)
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
		let last_confirm = input('�����ॹ����פ��ѹ����ʤ���(y/N): ')
		if last_confirm =~ '^\cy'
			let notimestamp = 'true'
		endif
	endif

	" �إå��κ��. �桼�����إå����������
	" �񤭹��ߤ���������ʻ���
	" @REG
	let regbak = @"
	silent! execute "normal! gg3D"
	let @" = regbak
	execute ":setlocal fenc="

	" urlencode
	let body = []
	let cl = 1
	while cl <= line('$')
		let line = getline(cl)
		let line = iconv(line, &enc, enc)
		let line = s:PW_urlencode(line)
		call add(body, line . '%0A')
		let cl = cl + 1
	endwhile

	" urlencode ������ʸ���ˤ���¾�ξ�������
	let cmd = "encode_hint=" . s:PW_urlencode( iconv( '��', &enc, enc ) )
	let cmd = cmd . "&cmd=edit&page=" . s:PW_urlencode( iconv( b:pukiwiki_page, &enc, enc ) )
	let cmd = cmd . "&digest=" . b:pukiwiki_digest . "&write=" . s:PW_urlencode( iconv( '�ڡ����ι���', &enc, enc ) )
	let cmd = cmd . "&notimestamp=" . notimestamp
	let cmd = cmd . "&original="
	let cmd = cmd . "&msg="
	let body[0] = cmd . body[0]

	let post = tempname()
	call writefile(body, post, "b")
	let result = tempname()
	let cmd = "curl -s -o " . result . " -d @" . post . ' "' . url . '"'
	call s:PW_system(cmd)

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
			let page = b:pukiwiki_page
			call s:PW_get_edit_page(b:pukiwiki_site_name, top, 0)
			call echo(page . ' �������ޤ���')
			return
		endif

		" ����
		execute ":undo"
		execute ":set nomodified"
		execute ":setlocal nomodifiable"
		execute ":setlocal readonly"
		let site_name = b:pukiwiki_site_name
		let page      = b:pukiwiki_page

		" �񤭹��ߤ��褦�Ȥ����Хåե���̾��������'��������'���դ���
		" ���ߤΥ����С�������Ƥ��������'diffthis'��¹Ԥ��롣
		call s:PW_set_statusline(b:pukiwiki_site_name, '�������� ' . b:pukiwiki_page)
		execute ":diffthis"
		execute ":new"

		call s:PW_get_edit_page(site_name, page, 0)
		execute ":diffthis"
		if g:pukiwiki_debug
			echo "digest=[" . b:pukiwiki_digest . "] cmd=[" . cmd . "]"
			echo "&enc=" . &enc . ", enc=" . enc . ", page=" . b:pukiwiki_page
			echo "iconv=" . Byte2hex(iconv(b:pukiwiki_page, &enc, enc))
			echo "urlen=" . s:PW_urlencode( iconv( b:pukiwiki_page, &enc, enc ) )
			call s:VITAL.print_error('�����ξ��ͤ�ȯ��������������¾�Υ��顼�ǽ񤭹���ޤ���Ǥ�����' . result)
		else
			call s:VITAL.print_error('�����ξ��ͤ�ȯ��������������¾�Υ��顼�ǽ񤭹���ޤ���Ǥ�����')
			call delete(result)
		endif
		return 0
	endif

	call s:PW_get_edit_page(b:pukiwiki_site_name, b:pukiwiki_page, 0)

	" �������Ԥ˰�ư
	execute "normal! " . lineno . "G"
"	silent! echo 'update ' . b:pukiwiki_page
	if g:pukiwiki_debug
		" ��󤦤äȡ������Τ� debug �Ѥ�
		call echo('����������')
	endif


endfunction "}}}

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

" page open s:[top/attach/list/search] {{{
function! s:PW_get_top_page(site_name) "{{{

	let sitedict = g:pukiwiki_config[a:site_name]
	let top = sitedict['top']

	return s:PW_get_edit_page(a:site_name, top, 1)

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
	let result = s:PW_system(cmd)

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

	execute "normal! i" . a:site_name . " " . b:pukiwiki_page . s:pukivim_ro_menu 
	execute "normal! iź�եե�������� [[" . b:pukiwiki_page . "]]\n"
	execute "normal! i" . body

	call s:PW_endpage(a:site_name, a:page, 1)
endfunction "}}}

function! s:PW_show_page_list() "{{{

	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let url = url . '?cmd=list'
	let result = tempname()
	let cmd = 'curl -s -o ' . result . ' "' . url . '"'
	call s:PW_system(cmd)

	if ! filereadable(result)
		echo "cannot obtain the list: " . cmd
		return 
	endif

	call s:PW_newpage(b:pukiwiki_site_name, 'cmd=list')
	call s:PW_set_statusline(b:pukiwiki_site_name, b:pukiwiki_page)

	let body = s:PW_fileread(result)
	call delete(result)

	let body = iconv(body, enc, &enc)
	let body = substitute(body, '^.*<div id="body">\(.*\)<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<a id\_.\{-}<strong>\(\_.\{-}\)<\/strong><\/a>', '\[\[\1\]\]', 'g')
"	let body = substitute(body, '<li><a href=".\{-}">\(\_.\{-}\)<\/a><small>(.*)</small></li>', '\[\[\1\]\]', 'g')

	execute "normal! i" . body

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

	" page ̾�����ʤ��Τ�, decode ���ʤ��Ƥ��ɤ���������.
	" single quote &apos;  &#xxxx �ʤɤϤ��ʤ��Ȥ����ʤ��餷��.
	let cl = 1
	while cl <= line('$')
		let line = getline(cl)
		call setline(cl, s:HTML.decodeEntityReference(line))
		let cl = cl + 1
	endwhile

	execute ":setlocal noai"
	execute "normal! gg0i" . b:pukiwiki_site_name . " " . b:pukiwiki_page . s:pukivim_ro_menu


	call s:PW_endpage(b:pukiwiki_site_name, b:pukiwiki_page, 1)
endfunction "}}}

function! s:PW_show_search() "{{{

	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
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
	call s:PW_system(cmd)

	call s:PW_newpage(b:pukiwiki_site_name, 'cmd=search')
	call s:PW_set_statusline(b:pukiwiki_site_name, b:pukiwiki_page)

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
	execute "normal! GddggP0i" . b:pukiwiki_site_name . " " . b:pukiwiki_page . s:pukivim_ro_menu
	let @" = regbak

	call s:PW_endpage(b:pukiwiki_site_name, b:pukiwiki_page, 1)
endfunction "}}}
" }}}

function! pukiwiki#fileupload() range "{{{

	if !exists('b:pukiwiki_site_name')
		return 
	endif

	let sitedict = g:pukiwiki_config[b:pukiwiki_site_name]
	let url = sitedict['url']
	let enc = sitedict['encode']
	let top = sitedict['top']

	let pass = input('�ѥ����: ')

	let enc_page = iconv(b:pukiwiki_page, &enc, enc)
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
		let result = s:PW_system(fcmd)
		let errcode = s:VITAL.get_last_status()
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

" g:motion {{{

function! pukiwiki#jump()  "{{{
	if !exists('b:pukiwiki_site_name')
		return 
	endif
	if line('.') < 4
		" �إå���ʬ
		let cur = s:PW_matchstr_undercursor('\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]')
	else
		let cur = s:PW_matchstr_undercursor(s:bracket_name)
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
		call s:VITAL.print_error('�ѹ�����¸����Ƥ��ޤ���')
		return
	endif

	let cur = substitute(cur, '\[\[\(.*\)\]\]', '\1', '')
	if line('.') < 4
		if cur == '�ȥå�'
			call s:PW_get_top_page(b:pukiwiki_site_name)
		elseif cur == '�������'
			if b:pukiwiki_page == 'FormattingRules' || b:pukiwiki_page == 'RecentChanges'
				call s:PW_get_source_page(b:pukiwiki_site_name, b:pukiwiki_page)
			else
				call s:PW_get_edit_page(b:pukiwiki_site_name, b:pukiwiki_page, 0)
			endif
		elseif cur == '����'
			let page = input('�����ڡ���̾: ')
			if page == ''
				return
			endif
			call s:PW_get_edit_page(b:pukiwiki_site_name, page, 1)
		elseif cur == '����'
			call s:PW_show_page_list()
		elseif cur == 'ñ�측��'
			call s:PW_show_search()
		elseif cur == 'ź��'
			call s:PW_show_attach(b:pukiwiki_site_name, b:pukiwiki_page)
		elseif cur == '�ǽ�����'
			let page = 'RecentChanges'
			call s:PW_get_source_page(b:pukiwiki_site_name, page)
		elseif cur == '�إ��'
			call s:PW_get_source_page(b:pukiwiki_site_name, 'FormattingRules')
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

	call s:PW_get_edit_page(b:pukiwiki_site_name, cur, 1)
endfunction "}}}

function! pukiwiki#move_next_bracket() "{{{
	let tmp = @/
	let @/ = s:bracket_name
	silent! execute "normal! n"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}

function! pukiwiki#move_prev_bracket() "{{{
	let tmp = @/
	let @/ = s:bracket_name
	execute "normal! hhh"
	silent! execute "normal! N"
	execute "normal! ll"
	let @/ = tmp
endfunction "}}}
" }}}

" s:alice.vim {{{

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
      let result .= ch
    elseif ch == ' '
      let result .= '+'
    else
	  let result .= printf("%%%02X", char2nr(ch))
    endif
  endwhile
  return result
endfunction "}}}

function! s:PW_system(cmd) " {{{
	return s:VITAL.system(a:cmd)
endfunction " }}}

function! s:PW_fileread(filename) "{{{
  if filereadable(a:filename)
    return join(readfile(a:filename, 'b'), "\n")
  endif
  return ''
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

" vim:set foldmethod=marker:
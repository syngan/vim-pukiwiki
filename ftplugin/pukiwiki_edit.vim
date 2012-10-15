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
" }}}

let s:pukivim_ro_menu = "\n[[�ȥå�]] [[ź��]] [[����]] [[����]] [[ñ�측��]] [[�ǽ�����]] [[�إ��]]\n------------------------------------------------------------------------------\n"
"let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
let s:bracket_name = '\[\[\%(\s\)\@!:\=[^\r\n\t[\]<>#&":]\+:\=\%(\s\)\@<!\]\]'
"let s:bracket_name = '\[\[\_.\{-}\]\]'

try
function! s:PW_move()  "{{{
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
"			let g:pukiwiki_current_site_top = b:top
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:top)
		elseif cur == '�����'
"			let g:pukiwiki_current_site_top = b:top
			if b:page == 'FormattingRules' || b:page == 'RecentChanges'
				call PW_get_source_page(b:site_name, b:url, b:enc, b:top, b:page)
			else
				call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, b:page)
			endif
		elseif cur == '����'
			let page = input('�����ڡ���̾: ')
			if page == ''
				return
			endif
			call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, page)
		elseif cur == '����'
			call s:PW_show_page_list()
		elseif cur == 'ñ�측��'
			call s:PW_show_search()
		elseif cur == 'ź��'
			call s:PW_show_attach(b:site_name, b:url, b:enc, b:top, b:page)
		elseif cur == '�ǽ�����'
			let page = 'RecentChanges'
			call PW_get_source_page(b:site_name, b:url, b:enc, b:top, page)
		elseif cur == '�إ��'
			call PW_get_source_page(b:site_name, b:url, b:enc, b:top, 'FormattingRules')
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

"	echo cur
"	let g:pukiwiki_current_site_name = b:site_name
"	let g:pukiwiki_current_site_top = b:top
	call PW_get_edit_page(b:site_name, b:url, b:enc, b:top, cur)
endfunction "}}}
catch /^Vim\%((\a\+)\)\?:E127/
endtry

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

try
function! s:PW_show_attach(site_name, url, enc, top, page) "{{{
"----------------------------------------------
" ź�եե������Ѥβ��̤�ɽ������.
" ɽ�������˥��ޥ�ɤ����������Τۤ��������Τ���
"----------------------------------------------
	" ź�եե�����ΰ���
	let enc_page = iconv(a:page, &enc, a:enc)
	let enc_page = PW_urlencode(enc_page)
	let url = a:url . '?plugin=attach&pcmd=list&refer=' . enc_page
	
	let tmp = tempname()
	
	let cmd = "curl -s -o " . tmp .' "'. url . '"'
	let result = system(cmd)

	let body = PW_fileread(tmp)
	let body = iconv(body, a:enc, &enc)
	let body = substitute(body, '^.*\(<div id="body">.*<hr class="full_hr" />\).*$', '\1', '')
	let body = substitute(body, '^.*<div id="body">.*<ul>\(.*\)</ul>.*<hr class="full_hr" />.*$', '\1', '')
	let body = substitute(body, '<span class="small">.\{-}</span>\n', '', 'g')
	let body = substitute(body, ' </li>\n', '', 'g')
	let body = substitute(body, ' <li><a.\{-} title="\(.\{-}\)">\(.\{-}\)</a>', '\2\t(\1)', 'g')
	" index.php?plugin=attach&pcmd=list&refer=$page

	" [ź�եե����뤬����ޤ���] �б�
	let body = substitute(body, '<.\{-}>', '', 'g')
	let body = substitute(body, '\n\n*', '\n', 'g')

	call PW_newpage(a:site_name, a:url, a:enc, a:top, a:page)
"	execute ":e! ++enc=" . a:enc
	let status_line = b:page . ' ' . b:site_name
	let status_line = escape(status_line, ' ')
	silent! execute ":f " . status_line

	execute "normal! i" . a:site_name . " " . b:page . s:pukivim_ro_menu 
	execute "normal! iź�եե�������� [[" . b:page . "]]\n"
	execute "normal! i" . body

	call PW_endpage(a:site_name, a:url, a:enc, a:top, a:page, 1)
endfunction "}}}
catch /^Vim\%((\a\+)\)\?:E127/
endtry

try
function! s:PW_show_page_list() "{{{
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


"	runtime! ftplugin/pukiwiki_edit.vim
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

	" ����ФäƲù�
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

	call AL_decode_entityreference_with_range('%')

	call PW_endpage(site_name, url, enc, top, page, 1)
endfunction "}}}
catch /^Vim\%((\a\+)\)\?:E127/
endtry

try
function! s:PW_show_search() "{{{
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
	let cmd = 'curl -s -o ' . result . ' -d encode_hint=' . PW_urlencode('��')
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
"	runtime! ftplugin/pukiwiki_edit.vim
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

	" �ǽ��Ԥ� [... 10 �ڡ������Ĥ���ޤ���] ��å�����
	" �����ǽ�ˤ���
	execute "normal! GddggP0i" . b:site_name . " " . b:page . s:pukivim_ro_menu

	call PW_endpage(site_name, url, enc, top, b:page, 1)
endfunction "}}}
catch /^Vim\%((\a\+)\)\?:E127/
endtry

try
function! PW_fileupload() range "{{{

	let pass = input('�ѥ����: ')

	let enc_page = iconv(b:page, &enc, b:enc)
	let enc_page = PW_urlencode(enc_page)

	let tmpfile = tempname()
	let cmd = 'curl -s -o ' . tmpfile . ' -F encode_hint=' . PW_urlencode('��')
	let cmd = cmd . ' -F plugin=attach'
	let cmd = cmd . ' -F pcmd=post'
	let cmd = cmd . ' -F refer=' . enc_page
	let cmd = cmd . ' -F pass=' . pass 

    for linenum in range(a:firstline, a:lastline)
        "Replace loose ampersands (as in DeAmperfy())...
        let curr_line   = getline(linenum)

		" �����Ĥ���ʬ�ǥ����å����뤫.
		" file ���ɤ�뤫. directory �Ǥʤ���.

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
catch /^Vim\%((\a\+)\)\?:E127/
endtry


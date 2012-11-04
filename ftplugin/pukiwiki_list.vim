" vim: set ts=4 sts=4 sw=4 noet ai fdm=marker:
" $Id: pukiwiki_list.vim 10 2008-07-27 07:34:08Z ishii $

nnoremap <silent> <buffer> <CR>  :call <SID>PW_read()<CR>
nnoremap <silent> <buffer> <TAB> :call <SID>PW_list_move()<CR>

function! s:PW_list_move()
	let tmp = @/
	let @/ = '^.*\t\+http://.*\t\+.*$'
	silent! execute "normal! n"
	let @/ = tmp
endfunction

function! s:PW_read()
	let line = getline('.')
	if line !~ '^.*\t\+http://.*\t\+.*$'
		return
	endif
	let site_name = substitute(line , '^\([^\t]*\)\t\+http.*$' , '\1' , '')
	let url       = substitute(line , '.*\(http.*\)\t\+.*'     , '\1' , '')
	let enc       = substitute(line , '^.*\t\+\(.*\)$'         , '\1' , '')
	let page      = substitute(url  , '.*?\([^\t]*\)\t*'       , '\1' , '')
	let url       = substitute(url  , '^\(.*\)?.*'             , '\1' , '')
	let top       = page
	if &modified
		execute ":w"
	endif

	call PW_get_edit_page(site_name, url, enc, top, page, 1)
endfunction


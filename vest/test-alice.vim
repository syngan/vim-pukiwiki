" Tests for vesting.
" Unite vesting:.

"scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" get s:" {{{
function! s:sid()
	let sfile = expand('<sfile>')
	let snr = matchstr(sfile, '<SNR>\zs\d\+\ze_snr$')
	return printf('<SNR>%s_', snr)
endfunction
 
function! s:path2snr(path)
	redir => _
	silent! scriptnames
	redir END
	let scripts = split(_, '\n')
	call filter(scripts, 'v:val =~# a:path')
	cal map(scripts, 'matchlist(v:val, ''^\s*\(\d*\):\s*\(\S*\)\s*$'')')
	let scripts = map(scripts, '{''snr'': v:val[1], ''path'': v:val[2]}')
	return empty(scripts) ? '' : scripts[0].snr
endfunction

silent! let pukiver = pukiwiki#version()
let pw = s:path2snr("autoload/pukiwiki.vim")
" }}}

Context Alice.run() " {{{
	It 'url encode' " {{{
		let F = function('<SNR>' . pw . '_PW_urlencode')
		Should 'abc' == F('abc')
		Should '%A4%C1%A4%E3' == F("\xA4\xC1\xA4\xE3")
		Should '%A4%C1%A4%E5' == F("\xA4\xC1\xA4\xE5")
		Should '%A4%C1%A4%E7' == F("\xA4\xC1\xA4\xE7")
	End " }}}
End

Fin " }}}

" Context Write.run() " {{{
" 	It 'write file' " {{{
" 	End " }}}
" Fin " }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:

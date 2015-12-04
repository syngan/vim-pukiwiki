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

if exists('b:loaded_pukiwiki')
  finish
 endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,pukiwiki#complete
			\ PukiWiki :call pukiwiki#PukiWiki(<f-args>)
command! -nargs=* PukiWikiJumpMenu :call pukiwiki#jump_menu(<f-args>)

let b:loaded_pukiwiki = 1

function! s:set_global_variable(key, default)
  if !has_key(g:, a:key)
    let g:[a:key] = a:default
  endif
endfunction

call s:set_global_variable('pukiwiki_timestamp_update',        -1)
call s:set_global_variable('pukiwiki_debug',                    0)
call s:set_global_variable('pukiwiki_show_header',              0)
call s:set_global_variable('pukiwiki_no_default_key_mappings',  0)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker

let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
  let s:V = a:V

  let s:Prelude = s:V.import('Prelude')
  let s:String = s:V.import('Data.String')
endfunction

function! s:_vital_depends()
  return ['Data.String', 'Prelude']
endfunction

function! s:__urlencode_char(c)
  let utf = iconv(a:c, &encoding, "utf-8")
  if utf == ""
    let utf = a:c
  endif
  let s = ""
  for i in range(strlen(utf))
    let s .= printf("%%%02X", char2nr(utf[i]))
  endfor
  return s
endfunction

function! s:decodeURI(str)
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
  return ret
endfunction

function! s:escape(str)
  return substitute(a:str, '[^a-zA-Z0-9_.~/-]', '\=s:__urlencode_char(submatch(0))', 'g')
endfunction

function! s:encodeURI(items)
  let ret = ''
  if s:Prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURI(a:items[key])
    endfor
  elseif s:Prelude.is_list(a:items)
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let ret = substitute(a:items, '[^a-zA-Z0-9_.~-]', '\=s:__urlencode_char(submatch(0))', 'g')
  endif
  return ret
endfunction

function! s:encodeURIComponent(items)
  let ret = ''
  if s:Prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURIComponent(a:items[key])
    endfor
  elseif s:Prelude.is_list(a:items)
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let items = iconv(a:items, &enc, "utf-8")
    let len = strlen(items)
    let i = 0
    while i < len
      let ch = items[i]
      if ch =~# '[0-9A-Za-z-._~!''()*]'
        let ret .= ch
      elseif ch == ' '
        let ret .= '+'
      else
        let ret .= '%' . substitute('0' . s:String.nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
      endif
      let i = i + 1
    endwhile
  endif
  return ret
endfunction

let s:default_settings = {
\   'method': 'GET',
\   'headers': {},
\   'client': executable('curl') ? 'curl' :
\             executable('wget') ? 'wget' : '',
\   'maxRedirect': 20,
\   'retry': 1,
\ }
function! s:request(...)
  let settings = {}
  for arg in a:000
    if s:Prelude.is_dict(arg)
      let settings = extend(settings, arg, 'keep')
    elseif s:Prelude.is_string(arg)
      if has_key(settings, 'url')
        let settings.method = settings.url
      endif
      let settings.url = arg
    endif
    unlet arg
  endfor
  let s:default_settings.headers = {}
  call extend(settings, s:default_settings, 'keep')
  let settings.method = toupper(settings.method)
  if !has_key(settings, 'url')
    throw 'Vital.Web.Http.request(): "url" parameter is required.'
  endif
  if !has_key(s:clients, settings.client)
    throw 'Vital.Web.Http.request(): Unknown client "' . settings.client . "'"
  endif
  if has_key(settings, 'contentType')
    let settings.headers['Content-Type'] = settings.contentType
  endif
  if has_key(settings, 'param')
    if s:Prelude.is_dict(settings.param)
      let getdatastr = s:encodeURI(settings.param)
    else
      let getdatastr = settings.param
    endif
    if strlen(getdatastr)
      let settings.url .= '?' . getdatastr
    endif
  endif
  let settings._file = {}
  if has_key(settings, 'data')
    if s:Prelude.is_dict(settings.data)
      let postdata = [s:encodeURI(settings.data)]
    elseif s:Prelude.is_list(settings.data)
      let postdata = settings.data
    else
      let postdata = split(settings.data, "\n")
    endif
    let settings._file.post = tempname()
    call writefile(postdata, settings._file.post, "b")
  endif

  let quote = &shellxquote == '"' ?  "'" : '"'
  let [header, content] = s:clients[settings.client](settings, quote)

  for file in values(settings._file)
    if filereadable(file)
      call delete(file)
    endif
  endfor

  return s:_build_response(header, content)
endfunction

let s:cerr = {}
let s:cerr[1] = 'Unsupported protocol. This build of curl has no support for this protocol.'
let s:cerr[2] = 'Failed to initialize.'
let s:cerr[3] = 'URL malformed. The syntax was not correct.'
let s:cerr[4] = 'A feature or option that was needed to perform the desired request was not enabled or was explicitly disabled at buildtime. To make curl able to do this, you probably need another build of libcurl!'
let s:cerr[5] = 'Couldn''t resolve proxy. The given proxy host could not be resolved.'
let s:cerr[6] = 'Couldn''t resolve host. The given remote host was not resolved.'
let s:cerr[7] = 'Failed to connect to host.'
let s:cerr[8] = 'FTP weird server reply. The server sent data curl couldn''t parse.'
let s:cerr[9] = 'FTP access denied. The server denied login or denied access to the particular resource or directory you wanted to reach. Most often you tried to change to a directory that doesn''t exist on the server.'
let s:cerr[11] = 'FTP weird PASS reply. Curl couldn''t parse the reply sent to the PASS request.'
let s:cerr[13] = 'FTP weird PASV reply, Curl couldn''t parse the reply sent to the PASV request.'
let s:cerr[14] = 'FTP weird 227 format. Curl couldn''t parse the 227-line the server sent.'
let s:cerr[15] = 'FTP can''t get host. Couldn''t resolve the host IP we got in the 227-line.'
let s:cerr[17] = 'FTP couldn''t set binary. Couldn''t change transfer method to binary.'
let s:cerr[18] = 'Partial file. Only a part of the file was transferred.'
let s:cerr[19] = 'FTP couldn''t download/access the given file, the RETR (or similar) command failed.'
let s:cerr[21] = 'FTP quote error. A quote command returned error from the server.'
let s:cerr[22] = 'HTTP page not retrieved. The requested url was not found or returned another error with the HTTP error code being 400 or above. This return code only appears if -f, --fail is used.'
let s:cerr[23] = 'Write error. Curl couldn''t write data to a local filesystem or similar.'
let s:cerr[25] = 'FTP couldn''t STOR file. The server denied the STOR operation, used for FTP uploading.'
let s:cerr[26] = 'Read error. Various reading problems.'
let s:cerr[27] = 'Out of memory. A memory allocation request failed.'
let s:cerr[28] = 'Operation timeout. The specified time-out period was reached according to the conditions.'
let s:cerr[30] = 'FTP PORT failed. The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead!'
let s:cerr[31] = 'FTP couldn''t use REST. The REST command failed. This command is used for resumed FTP transfers.'
let s:cerr[33] = 'HTTP range error. The range "command" didn''t work.'
let s:cerr[34] = 'HTTP post error. Internal post-request generation error.'
let s:cerr[35] = 'SSL connect error. The SSL handshaking failed.'
let s:cerr[36] = 'FTP bad download resume. Couldn''t continue an earlier aborted download.'
let s:cerr[37] = 'FILE couldn''t read file. Failed to open the file. Permissions?'
let s:cerr[38] = 'LDAP cannot bind. LDAP bind operation failed.'
let s:cerr[39] = 'LDAP search failed.'
let s:cerr[41] = 'Function not found. A required LDAP function was not found.'
let s:cerr[42] = 'Aborted by callback. An application told curl to abort the operation.'
let s:cerr[43] = 'Internal error. A function was called with a bad parameter.'
let s:cerr[45] = 'Interface error. A specified outgoing interface could not be used.'
let s:cerr[47] = 'Too many redirects. When following redirects, curl hit the maximum amount.'
let s:cerr[48] = 'Unknown option specified to libcurl. This indicates that you passed a weird option to curl that was passed on to libcurl and rejected. Read up in the manual!'
let s:cerr[49] = 'Malformed telnet option.'
let s:cerr[51] = 'The peer''s SSL certificate or SSH MD5 fingerprint was not OK.'
let s:cerr[52] = 'The server didn''t reply anything, which here is considered an error.'
let s:cerr[53] = 'SSL crypto engine not found.'
let s:cerr[54] = 'Cannot set SSL crypto engine as default.'
let s:cerr[55] = 'Failed sending network data.'
let s:cerr[56] = 'Failure in receiving network data.'
let s:cerr[58] = 'Problem with the local certificate.'
let s:cerr[59] = 'Couldn''t use specified SSL cipher.'
let s:cerr[60] = 'Peer certificate cannot be authenticated with known CA certificates.'
let s:cerr[61] = 'Unrecognized transfer encoding.'
let s:cerr[62] = 'Invalid LDAP URL.'
let s:cerr[63] = 'Maximum file size exceeded.'
let s:cerr[64] = 'Requested FTP SSL level failed.'
let s:cerr[65] = 'Sending the data requires a rewind that failed.'
let s:cerr[66] = 'Failed to initialise SSL Engine.'
let s:cerr[67] = 'The user name, password, or similar was not accepted and curl failed to log in.'
let s:cerr[68] = 'File not found on TFTP server.'
let s:cerr[69] = 'Permission problem on TFTP server.'
let s:cerr[70] = 'Out of disk space on TFTP server.'
let s:cerr[71] = 'Illegal TFTP operation.'
let s:cerr[72] = 'Unknown TFTP transfer ID.'
let s:cerr[73] = 'File already exists (TFTP).'
let s:cerr[74] = 'No such user (TFTP).'
let s:cerr[75] = 'Character conversion failed.'
let s:cerr[76] = 'Character conversion functions required.'
let s:cerr[77] = 'Problem with reading the SSL CA cert (path? access rights?).'
let s:cerr[78] = 'The resource referenced in the URL does not exist.'
let s:cerr[79] = 'An unspecified error occurred during the SSH session.'
let s:cerr[80] = 'Failed to shut down the SSL connection.'
let s:cerr[82] = 'Could not load CRL file, missing or wrong format (added in 7.19.0).'
let s:cerr[83] = 'Issuer check failed (added in 7.19.0).'
let s:cerr[84] = 'The FTP PRET command failed'
let s:cerr[85] = 'RTSP: mismatch of CSeq numbers'
let s:cerr[86] = 'RTSP: mismatch of Session Identifiers'
let s:cerr[87] = 'unable to parse FTP file list'
let s:cerr[88] = 'FTP chunk callback reported error'
let s:cerr[89] = 'No connection available, the session will be queued'
let s:cerr[-1] = 'More error codes will appear here in future releases. The existing ones are meant to never change.'


let s:clients = {}
function! s:clients.curl(settings, quote)
  let command = get(a:settings, 'command', 'curl')
  let a:settings._file.header = tempname()
  let command .= ' --dump-header ' . a:quote . a:settings._file.header . a:quote
  let has_output_file = has_key(a:settings, 'outputFile')
  if has_output_file
    let output_file = a:settings.outputFile
  else
    let output_file = tempname()
    let a:settings._file.content = output_file
  endif
  let command .= ' --output ' . a:quote . output_file . a:quote
  let command .= ' -L -s -k -X ' . a:settings.method
  let command .= ' --max-redirs ' . a:settings.maxRedirect
  let command .= s:_make_header_args(a:settings.headers, '-H ', a:quote)
  let timeout = get(a:settings, 'timeout', '')
  let command .= ' --retry ' . a:settings.retry
  if timeout =~# '^\d\+$'
    let command .= ' --max-time ' . timeout
  endif
  if has_key(a:settings, 'username')
    let auth = a:settings.username . ':' . get(a:settings, 'password', '')
    let command .= ' --anyauth --user ' . a:quote . auth . a:quote
  endif
  let command .= ' ' . a:quote . a:settings.url . a:quote
  if has_key(a:settings._file, 'post')
    let file = a:settings._file.post
    let command .= ' --data-binary @' . a:quote . file . a:quote
  endif

  call s:Prelude.system(command)
  let retcode = s:Prelude.get_last_status()

  let headerstr = s:_readfile(a:settings._file.header)
  let header_chunks = split(headerstr, "\r\n\r\n")
  let header = split(get(header_chunks, -1, ''), "\r\n")
  if has_output_file
    let content = ''
  else
    let content = s:_readfile(output_file)
  endif
  if retcode != 0
    if !has_key(s:cerr, retcode)
      let retcode = -1
    endif
    throw 'Vital.Web.Http.request(syngan): curl: ' . s:cerr[retcode]
  endif

  return [header, content]
endfunction

let s:werr = {}
let s:werr[1] = 'Generic error code.'
let s:werr[2] = 'Parse error---for instance, when parsing command-line options, the .wgetrc or .netrc...'
let s:werr[3] = 'File I/O error.'
let s:werr[4] = 'Network failure.'
let s:werr[5] = 'SSL verification failure.'
let s:werr[6] = 'Username/password authentication failure.'
let s:werr[7] = 'Protocol errors.'
let s:werr[8] = 'Server issued an error response.'

function! s:clients.wget(settings, quote)
  let command = get(a:settings, 'command', 'wget')
  let method = a:settings.method
  if method ==# 'HEAD'
    let command .= ' --spider'
  elseif method !=# 'GET' && method !=# 'POST'
    let a:settings.headers['X-HTTP-Method-Override'] = a:settings.method
  endif
  let a:settings._file.header = tempname()
  let command .= ' -o ' . a:quote . a:settings._file.header . a:quote
  let has_output_file = has_key(a:settings, 'outputFile')
  if has_output_file
    let output_file = a:settings.outputFile
  else
    let output_file = tempname()
    let a:settings._file.content = output_file
  endif
  let command .= ' -O ' . a:quote . output_file . a:quote
  let command .= ' --server-response -q -L '
  let command .= ' --max-redirect=' . a:settings.maxRedirect
  let command .= s:_make_header_args(a:settings.headers, '--header=', a:quote)
  let timeout = get(a:settings, 'timeout', '')
  let command .= ' --tries=' . a:settings.retry
  if timeout =~# '^\d\+$'
    let command .= ' --timeout=' . timeout
  endif
  if has_key(a:settings, 'username')
    let command .= ' --http-user=' . a:quote . a:settings.username . a:quote
  endif
  if has_key(a:settings, 'password')
    let command .= ' --http-password=' . a:quote . a:settings.password . a:quote
  endif
  let command .= ' ' . a:quote . a:settings.url . a:quote
  if has_key(a:settings._file, 'post')
    let file = a:settings._file.post
    let command .= ' --post-file=' . a:quote . file . a:quote
  endif

  call s:Prelude.system(command)
  let retcode = s:Prelude.get_last_status()

  if filereadable(a:settings._file.header)
    let header_lines = readfile(a:settings._file.header, 'b')
    call map(header_lines, 'matchstr(v:val, "^\\s*\\zs.*")')
    let headerstr = join(header_lines, "\n")
    let header_chunks = split(headerstr, '\n\zeHTTP/1\.\d')
    let header = split(get(header_chunks, -1, ''), "\n")
  else
    let header = []
  endif
  if has_output_file
    let content = ''
  else
    let content = s:_readfile(output_file)
  endif

  if retcode > 1 && has_key(s:werr, retcode)
    throw 'Vital.Web.Http.request(syngan): wget: ' . s:werr[retcode]
  endif
  return [header, content]
endfunction

function! s:get(url, ...)
  let settings = {
  \    'url': a:url,
  \    'param': a:0 > 0 ? a:1 : {},
  \    'headers': a:0 > 1 ? a:2 : {},
  \ }
  return s:request(settings)
endfunction

function! s:post(url, ...)
  let settings = {
  \    'url': a:url,
  \    'data': a:0 > 0 ? a:1 : {},
  \    'headers': a:0 > 1 ? a:2 : {},
  \    'method': a:0 > 2 ? a:3 : 'POST',
  \ }
  return s:request(settings)
endfunction

function! s:_readfile(file)
  if filereadable(a:file)
    return join(readfile(a:file, 'b'), "\n")
  endif
  return ''
endfunction

function! s:_build_response(header, content)
  let response = {
  \   'header' : a:header,
  \   'content': a:content,
  \   'status': 0,
  \   'statusText': '',
  \   'success': 0,
  \ }

  if !empty(a:header)
    let status_line = get(a:header, 0)
    let matched = matchlist(status_line, '^HTTP/1\.\d\s\+\(\d\+\)\s\+\(.*\)')
    if !empty(matched)
      let [status, statusText] = matched[1 : 2]
      let response.status = status - 0
      let response.statusText = statusText
      let response.success = status =~# '^2'
      call remove(a:header, 0)
    endif
  endif
  return response
endfunction

function! s:_make_header_args(headdata, option, quote)
  let args = ''
  for [key, value] in items(a:headdata)
    if s:Prelude.is_windows()
      let value = substitute(value, '"', '"""', 'g')
    endif
    let args .= " " . a:option . a:quote . key . ": " . value . a:quote
  endfor
  return args
endfunction

function! s:parseHeader(headers)
  " FIXME: User should be able to specify the treatment method of the duplicate item.
  let header = {}
  for h in a:headers
    let matched = matchlist(h, '^\([^:]\+\):\s*\(.*\)$')
    if !empty(matched)
      let [name, value] = matched[1 : 2]
      let header[name] = value
    endif
  endfor
  return header
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:

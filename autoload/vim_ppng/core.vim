scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Resolve URL from input
" @param input string - Either a full URL or a path
" @return string - Full URL
function! vim_ppng#core#resolve_url(input) abort
  " Check if input is already a full URL
  if a:input =~# '^\(http://\|https://\)'
    return a:input
  endif

  " Get the ppng server URL
  let l:server = get(g:, 'ppng_server', 'https://ppng.io')

  " Strip trailing slashes from server
  let l:server = substitute(l:server, '/\+$', '', '')

  " Strip leading slashes from path
  let l:path = substitute(a:input, '^/\+', '', '')

  " Combine server and path
  return l:server . '/' . l:path
endfunction

" Get text from buffer
" @param mode string - 'normal' or 'visual'
" @param start_line number - Start line number (for visual mode)
" @param end_line number - End line number (for visual mode)
" @return string - Text content with newlines
function! vim_ppng#core#get_text(mode, start_line, end_line) abort
  if a:mode ==# 'normal'
    " Get all lines from the buffer
    let l:lines = getline(1, '$')
  elseif a:mode ==# 'visual'
    " Get lines from start_line to end_line
    let l:lines = getline(a:start_line, a:end_line)
  else
    " Invalid mode, return empty string
    return ''
  endif

  " Join lines with newlines
  return join(l:lines, "\n")
endfunction

" Prompt user for path or URL
" @param default_value string - Default value to show in prompt
" @return string - User input or empty string if canceled
function! vim_ppng#core#prompt_for_path(default_value) abort
  let l:prompt = 'Ppng path or URL: '

  " Use mock if provided (for testing)
  if exists('g:Vim_ppng_input_mock')
    return g:Vim_ppng_input_mock
  endif

  " Try to get user input with default value
  try
    let l:user_input = input(l:prompt, a:default_value)
    return l:user_input
  catch
    " If input fails, return empty string
    return ''
  endtry
endfunction

" Path token that is replaced with a fresh random path
let s:RANDOM_TOKEN = '{random}'

" 32 characters without look-alikes (no l, o, 0, 1); 256 % 32 == 0 keeps
" every character equally likely.
let s:ALPHABET = 'abcdefghijkmnpqrstuvwxyz23456789'

" @param path string
" @return bool - whether path is the random token
function! vim_ppng#core#is_random_token(path) abort
  return a:path ==# s:RANDOM_TOKEN
endfunction

" Generate a hard-to-guess path.
" @param ... number - length (default 24, about 120 bits)
" @return string
function! vim_ppng#core#random_path(...) abort
  let l:len = a:0 ? a:1 : 24
  let l:path = ''
  for l:byte in s:random_bytes(l:len)
    let l:path .= s:ALPHABET[l:byte % 32]
  endfor
  return l:path
endfunction

" Read random bytes from /dev/urandom, falling back to sha256 of
" time/pid/tempname when that is not readable (e.g. Windows).
" @param n number
" @return list - numbers 0..255
function! s:random_bytes(n) abort
  if exists('*readblob') && filereadable('/dev/urandom')
    try
      let l:blob = readblob('/dev/urandom', 0, a:n)
      if len(l:blob) == a:n
        return map(range(a:n), 'l:blob[v:val]')
      endif
    catch
    endtry
  endif
  let l:bytes = []
  let l:seed = reltimestr(reltime()) . getpid() . tempname() . localtime()
  while len(l:bytes) < a:n
    let l:seed = sha256(l:seed . reltimestr(reltime()) . len(l:bytes))
    for l:i in range(0, 62, 2)
      call add(l:bytes, str2nr(l:seed[l:i : l:i + 1], 16))
    endfor
  endwhile
  return l:bytes[: a:n - 1]
endfunction

" Ask for a secret without echo and without touching any history.
" Tests can set g:Vim_ppng_secret_mock to a list of answers.
" @param prompt string
" @return string - '' when canceled
function! vim_ppng#core#prompt_secret(prompt) abort
  if exists('g:Vim_ppng_secret_mock')
    return empty(g:Vim_ppng_secret_mock) ? '' : remove(g:Vim_ppng_secret_mock, 0)
  endif
  try
    let l:secret = inputsecret(a:prompt)
  catch
    let l:secret = ''
  endtry
  redraw
  return l:secret
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

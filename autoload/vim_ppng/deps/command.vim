scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Upload text to URL using curl
" @param url string - Target URL
" @param text string - Text content to upload
" @param timeout number - Timeout in seconds
" @return dict - {'ok': v:true/v:false, 'code': N, 'stdout': [...], 'stderr': [...]}
function! vim_ppng#deps#command#curl_upload(url, text, timeout) abort
  " Check if curl is available (use mock if provided for testing)
  let l:has_curl = exists('g:Vim_ppng_executable_mock') ? g:Vim_ppng_executable_mock : executable('curl')
  if !l:has_curl
    return {
          \ 'ok': v:false,
          \ 'code': -1,
          \ 'stdout': [],
          \ 'stderr': ['curl command is not available']
          \ }
  endif

  " Use stub runner if provided (for testing)
  if exists('g:Vim_ppng_curl_runner')
    return call(g:Vim_ppng_curl_runner, [a:url, a:text, a:timeout, 'upload'])
  endif

  " Prepare curl command: curl -sS --globoff -m <timeout> -T - <url>
  let l:cmd = vim_ppng#deps#command#curl_prefix(a:timeout)
        \ . ' -T - ' . shellescape(a:url)

  " Execute command with text as stdin
  let l:output = systemlist(l:cmd, a:text)
  let l:exit_code = v:shell_error

  " Parse output and errors
  let l:stdout = []
  let l:stderr = []

  if l:exit_code == 0
    let l:stdout = l:output
  else
    " On error, systemlist output may contain error messages
    let l:stderr = l:output
  endif

  return {
        \ 'ok': l:exit_code == 0,
        \ 'code': l:exit_code,
        \ 'stdout': l:stdout,
        \ 'stderr': l:stderr
        \ }
endfunction

" Download content from URL using curl
" @param url string - Source URL
" @param timeout number - Timeout in seconds
" @return dict - {'ok': v:true/v:false, 'code': N, 'stdout': [...], 'stderr': [...]}
function! vim_ppng#deps#command#curl_download(url, timeout) abort
  " Check if curl is available (use mock if provided for testing)
  let l:has_curl = exists('g:Vim_ppng_executable_mock') ? g:Vim_ppng_executable_mock : executable('curl')
  if !l:has_curl
    return {
          \ 'ok': v:false,
          \ 'code': -1,
          \ 'stdout': [],
          \ 'stderr': ['curl command is not available']
          \ }
  endif

  " Use stub runner if provided (for testing)
  if exists('g:Vim_ppng_curl_runner')
    return call(g:Vim_ppng_curl_runner, [a:url, '', a:timeout, 'download'])
  endif

  " Prepare curl command: curl -sS --globoff -m <timeout> <url>
  let l:cmd = vim_ppng#deps#command#curl_prefix(a:timeout)
        \ . ' ' . shellescape(a:url)

  " Execute command
  let l:output = systemlist(l:cmd)
  let l:exit_code = v:shell_error

  " Parse output and errors
  let l:stdout = []
  let l:stderr = []

  if l:exit_code == 0
    let l:stdout = l:output
  else
    " On error, systemlist output may contain error messages
    let l:stderr = l:output
  endif

  return {
        \ 'ok': l:exit_code == 0,
        \ 'code': l:exit_code,
        \ 'stdout': l:stdout,
        \ 'stderr': l:stderr
        \ }
endfunction

" Upload the bytes of a file using curl --data-binary (used for encrypted data)
" @param url string - Target URL
" @param file string - File to upload
" @param timeout number - Timeout in seconds
" @return dict - {'ok': v:true/v:false, 'code': N, 'stdout': [...], 'stderr': [...]}
function! vim_ppng#deps#command#curl_upload_file(url, file, timeout) abort
  let l:has_curl = exists('g:Vim_ppng_executable_mock') ? g:Vim_ppng_executable_mock : executable('curl')
  if !l:has_curl
    return s:no_curl()
  endif

  " Use stub runner if provided (for testing); the 2nd argument is the file
  if exists('g:Vim_ppng_curl_runner')
    return call(g:Vim_ppng_curl_runner, [a:url, a:file, a:timeout, 'upload_file'])
  endif

  let l:cmd = vim_ppng#deps#command#curl_prefix(a:timeout)
        \ . ' -f -H ' . shellescape('Content-Type: application/octet-stream')
        \ . ' --data-binary ' . shellescape('@' . a:file)
        \ . ' ' . shellescape(a:url)
  return s:run(l:cmd)
endfunction

" Download into a file using curl -o (used for encrypted data)
" @param url string - Source URL
" @param file string - Existing file to overwrite (keeps its mode)
" @param timeout number - Timeout in seconds
" @return dict - {'ok': v:true/v:false, 'code': N, 'stdout': [...], 'stderr': [...]}
function! vim_ppng#deps#command#curl_download_file(url, file, timeout) abort
  let l:has_curl = exists('g:Vim_ppng_executable_mock') ? g:Vim_ppng_executable_mock : executable('curl')
  if !l:has_curl
    return s:no_curl()
  endif

  " Use stub runner if provided (for testing); it must write the file
  if exists('g:Vim_ppng_curl_runner')
    return call(g:Vim_ppng_curl_runner, [a:url, a:file, a:timeout, 'download_file'])
  endif

  let l:cmd = vim_ppng#deps#command#curl_prefix(a:timeout)
        \ . ' -f -o ' . shellescape(a:file)
        \ . ' ' . shellescape(a:url)
  return s:run(l:cmd)
endfunction

" Common start of every curl command.
" --globoff: '[', ']', '{' and '}' in a path are sent as they are instead of
" being expanded by curl into several requests.
" @param timeout number - Timeout in seconds
" @return string
function! vim_ppng#deps#command#curl_prefix(timeout) abort
  return 'curl -sS --globoff -m ' . string(a:timeout)
endfunction

function! s:no_curl() abort
  return {
        \ 'ok': v:false,
        \ 'code': -1,
        \ 'stdout': [],
        \ 'stderr': ['curl command is not available']
        \ }
endfunction

function! s:run(cmd) abort
  let l:output = systemlist(a:cmd)
  let l:exit_code = v:shell_error
  return {
        \ 'ok': l:exit_code == 0,
        \ 'code': l:exit_code,
        \ 'stdout': l:exit_code == 0 ? l:output : [],
        \ 'stderr': l:exit_code == 0 ? [] : l:output
        \ }
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

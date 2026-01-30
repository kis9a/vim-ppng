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

  " Prepare curl command: curl -sS -T - -m <timeout> <url>
  let l:escaped_url = shellescape(a:url)
  let l:timeout_str = string(a:timeout)
  let l:cmd = 'curl -sS -T - -m ' . l:timeout_str . ' ' . l:escaped_url

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

  " Prepare curl command: curl -sS -m <timeout> <url>
  let l:escaped_url = shellescape(a:url)
  let l:timeout_str = string(a:timeout)
  let l:cmd = 'curl -sS -m ' . l:timeout_str . ' ' . l:escaped_url

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

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

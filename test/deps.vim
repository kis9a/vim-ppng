scriptencoding utf-8

let s:suite = themis#suite('deps')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  " Clean up any existing stub
  if exists('g:Vim_ppng_curl_runner')
    unlet g:Vim_ppng_curl_runner
  endif
endfunction

function! s:suite.after_each() abort
  " Clean up
  if exists('g:Vim_ppng_curl_runner')
    unlet g:Vim_ppng_curl_runner
  endif
endfunction

" Test curl_upload with success stub
function! s:suite.test_curl_upload_success() abort
  let g:Vim_ppng_curl_runner = function('s:stub_success')

  let l:result = vim_ppng#deps#command#curl_upload('https://example.com/test', 'hello world', 30)

  call s:assert.true(l:result.ok)
  call s:assert.equals(0, l:result.code)
  call s:assert.equals(['success'], l:result.stdout)
  call s:assert.equals([], l:result.stderr)
endfunction

" Test curl_upload with failure stub
function! s:suite.test_curl_upload_failure() abort
  let g:Vim_ppng_curl_runner = function('s:stub_failure')

  let l:result = vim_ppng#deps#command#curl_upload('https://example.com/test', 'hello', 30)

  call s:assert.false(l:result.ok)
  call s:assert.equals(1, l:result.code)
  call s:assert.equals([], l:result.stdout)
  call s:assert.equals(['error'], l:result.stderr)
endfunction

" Test curl_download with success stub
function! s:suite.test_curl_download_success() abort
  let g:Vim_ppng_curl_runner = function('s:stub_download_success')

  let l:result = vim_ppng#deps#command#curl_download('https://example.com/test', 30)

  call s:assert.true(l:result.ok)
  call s:assert.equals(0, l:result.code)
  call s:assert.equals(['received', 'data'], l:result.stdout)
  call s:assert.equals([], l:result.stderr)
endfunction

" Test curl_download with failure stub
function! s:suite.test_curl_download_failure() abort
  let g:Vim_ppng_curl_runner = function('s:stub_failure')

  let l:result = vim_ppng#deps#command#curl_download('https://example.com/test', 30)

  call s:assert.false(l:result.ok)
  call s:assert.equals(1, l:result.code)
  call s:assert.equals([], l:result.stdout)
  call s:assert.equals(['error'], l:result.stderr)
endfunction

" Test timeout parameter is passed
function! s:suite.test_timeout_parameter() abort
  let g:Vim_ppng_curl_runner = function('s:stub_check_timeout')

  let l:result = vim_ppng#deps#command#curl_upload('https://example.com/test', 'data', 60)

  " stub_check_timeout returns the timeout in stdout for verification
  call s:assert.true(l:result.ok)
  call s:assert.equals(['timeout:60'], l:result.stdout)
endfunction

" Test zero timeout (unlimited)
function! s:suite.test_zero_timeout() abort
  let g:Vim_ppng_curl_runner = function('s:stub_check_timeout')

  let l:result = vim_ppng#deps#command#curl_upload('https://example.com/test', 'data', 0)

  call s:assert.true(l:result.ok)
  call s:assert.equals(['timeout:0'], l:result.stdout)
endfunction

" Stub functions
function! s:stub_success(url, text, timeout, mode) abort
  return {'ok': v:true, 'code': 0, 'stdout': ['success'], 'stderr': []}
endfunction

function! s:stub_failure(url, text, timeout, mode) abort
  return {'ok': v:false, 'code': 1, 'stdout': [], 'stderr': ['error']}
endfunction

function! s:stub_download_success(url, text, timeout, mode) abort
  return {'ok': v:true, 'code': 0, 'stdout': ['received', 'data'], 'stderr': []}
endfunction

function! s:stub_check_timeout(url, text, timeout, mode) abort
  return {'ok': v:true, 'code': 0, 'stdout': ['timeout:' . a:timeout], 'stderr': []}
endfunction

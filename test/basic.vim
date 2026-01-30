scriptencoding utf-8

let s:suite = themis#suite('basic')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  " Save original settings
  if exists('g:ppng_server')
    let s:save_server = g:ppng_server
  endif
endfunction

function! s:suite.after_each() abort
  " Restore settings
  if exists('s:save_server')
    let g:ppng_server = s:save_server
    unlet s:save_server
  elseif exists('g:ppng_server')
    unlet g:ppng_server
  endif
endfunction

" Test resolve_url with full URL
function! s:suite.test_resolve_url_full_http() abort
  let l:result = vim_ppng#core#resolve_url('http://example.com/test')
  call s:assert.equals('http://example.com/test', l:result)
endfunction

function! s:suite.test_resolve_url_full_https() abort
  let l:result = vim_ppng#core#resolve_url('https://example.com/test')
  call s:assert.equals('https://example.com/test', l:result)
endfunction

" Test resolve_url with path only
function! s:suite.test_resolve_url_path_only() abort
  let g:ppng_server = 'https://ppng.io'
  let l:result = vim_ppng#core#resolve_url('mypath')
  call s:assert.equals('https://ppng.io/mypath', l:result)
endfunction

" Test resolve_url with leading slash in path
function! s:suite.test_resolve_url_leading_slash() abort
  let g:ppng_server = 'https://ppng.io'
  let l:result = vim_ppng#core#resolve_url('/mypath')
  call s:assert.equals('https://ppng.io/mypath', l:result)
endfunction

" Test resolve_url with trailing slash in server
function! s:suite.test_resolve_url_trailing_slash() abort
  let g:ppng_server = 'https://ppng.io/'
  let l:result = vim_ppng#core#resolve_url('mypath')
  call s:assert.equals('https://ppng.io/mypath', l:result)
endfunction

" Test resolve_url with both slashes
function! s:suite.test_resolve_url_both_slashes() abort
  let g:ppng_server = 'https://ppng.io/'
  let l:result = vim_ppng#core#resolve_url('/mypath')
  call s:assert.equals('https://ppng.io/mypath', l:result)
endfunction

" Test get_text in normal mode
function! s:suite.test_get_text_normal() abort
  " Create a temporary buffer with test content
  new
  call setline(1, ['line1', 'line2', 'line3'])

  let l:result = vim_ppng#core#get_text('normal', 1, line('$'))
  call s:assert.equals("line1\nline2\nline3", l:result)

  " Clean up
  bwipeout!
endfunction

" Test get_text in visual mode
function! s:suite.test_get_text_visual() abort
  " Create a temporary buffer with test content
  new
  call setline(1, ['line1', 'line2', 'line3', 'line4', 'line5'])

  let l:result = vim_ppng#core#get_text('visual', 2, 4)
  call s:assert.equals("line2\nline3\nline4", l:result)

  " Clean up
  bwipeout!
endfunction

" Test get_text with single line
function! s:suite.test_get_text_single_line() abort
  new
  call setline(1, ['single'])

  let l:result = vim_ppng#core#get_text('normal', 1, 1)
  call s:assert.equals('single', l:result)

  " Clean up
  bwipeout!
endfunction

" Test get_text with empty buffer
function! s:suite.test_get_text_empty_buffer() abort
  new

  let l:result = vim_ppng#core#get_text('normal', 1, line('$'))
  call s:assert.equals('', l:result)

  " Clean up
  bwipeout!
endfunction

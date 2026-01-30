scriptencoding utf-8

let s:suite = themis#suite('history')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  " Save original settings
  if exists('g:ppng_history_max')
    let s:save_max = g:ppng_history_max
  endif

  " Clear history before each test
  call vim_ppng#internal#history#clear()
endfunction

function! s:suite.after_each() abort
  " Restore settings
  if exists('s:save_max')
    let g:ppng_history_max = s:save_max
    unlet s:save_max
  elseif exists('g:ppng_history_max')
    unlet g:ppng_history_max
  endif

  " Clean up history
  call vim_ppng#internal#history#clear()
endfunction

" Test basic addition
function! s:suite.test_add_single() abort
  let g:ppng_history_max = 10

  call vim_ppng#internal#history#add('https://example.com/test1')
  let l:history = vim_ppng#internal#history#get()

  call s:assert.equals(1, len(l:history))
  call s:assert.equals('https://example.com/test1', l:history[0])
endfunction

" Test multiple additions
function! s:suite.test_add_multiple() abort
  let g:ppng_history_max = 10

  call vim_ppng#internal#history#add('https://example.com/test1')
  call vim_ppng#internal#history#add('https://example.com/test2')
  call vim_ppng#internal#history#add('https://example.com/test3')

  let l:history = vim_ppng#internal#history#get()

  call s:assert.equals(3, len(l:history))
  call s:assert.equals('https://example.com/test3', l:history[0])
  call s:assert.equals('https://example.com/test2', l:history[1])
  call s:assert.equals('https://example.com/test1', l:history[2])
endfunction

" Test duplicate handling (move to front)
function! s:suite.test_duplicate_move_to_front() abort
  let g:ppng_history_max = 10

  call vim_ppng#internal#history#add('https://example.com/test1')
  call vim_ppng#internal#history#add('https://example.com/test2')
  call vim_ppng#internal#history#add('https://example.com/test3')
  call vim_ppng#internal#history#add('https://example.com/test2')

  let l:history = vim_ppng#internal#history#get()

  call s:assert.equals(3, len(l:history))
  call s:assert.equals('https://example.com/test2', l:history[0])
  call s:assert.equals('https://example.com/test3', l:history[1])
  call s:assert.equals('https://example.com/test1', l:history[2])
endfunction

" Test max limit
function! s:suite.test_max_limit() abort
  let g:ppng_history_max = 3

  call vim_ppng#internal#history#add('https://example.com/test1')
  call vim_ppng#internal#history#add('https://example.com/test2')
  call vim_ppng#internal#history#add('https://example.com/test3')
  call vim_ppng#internal#history#add('https://example.com/test4')

  let l:history = vim_ppng#internal#history#get()

  call s:assert.equals(3, len(l:history))
  call s:assert.equals('https://example.com/test4', l:history[0])
  call s:assert.equals('https://example.com/test3', l:history[1])
  call s:assert.equals('https://example.com/test2', l:history[2])
endfunction

" Test get returns copy
function! s:suite.test_get_returns_copy() abort
  let g:ppng_history_max = 10

  call vim_ppng#internal#history#add('https://example.com/test1')

  let l:history1 = vim_ppng#internal#history#get()
  call add(l:history1, 'https://example.com/fake')

  let l:history2 = vim_ppng#internal#history#get()

  call s:assert.equals(1, len(l:history2))
  call s:assert.equals('https://example.com/test1', l:history2[0])
endfunction

" Test clear
function! s:suite.test_clear() abort
  let g:ppng_history_max = 10

  call vim_ppng#internal#history#add('https://example.com/test1')
  call vim_ppng#internal#history#add('https://example.com/test2')

  call vim_ppng#internal#history#clear()

  let l:history = vim_ppng#internal#history#get()
  call s:assert.equals(0, len(l:history))
endfunction

" Test history disabled when max=0
function! s:suite.test_disabled_when_max_zero() abort
  let g:ppng_history_max = 0

  call vim_ppng#internal#history#add('https://example.com/test1')
  call vim_ppng#internal#history#add('https://example.com/test2')

  let l:history = vim_ppng#internal#history#get()
  call s:assert.equals(0, len(l:history))
endfunction

" Test history re-enabled after setting max
function! s:suite.test_reenable_after_zero() abort
  let g:ppng_history_max = 0

  call vim_ppng#internal#history#add('https://example.com/test1')

  let g:ppng_history_max = 10
  call vim_ppng#internal#history#add('https://example.com/test2')

  let l:history = vim_ppng#internal#history#get()
  call s:assert.equals(1, len(l:history))
  call s:assert.equals('https://example.com/test2', l:history[0])
endfunction

scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Script-local variable to store history (latest first)
let s:history = []

" Add URL to history
" @param url string - URL to add to history
function! vim_ppng#internal#history#add(url) abort
  " Get the maximum history limit (default: 10)
  let l:max = get(g:, 'ppng_history_max', 10)

  " If limit is 0, don't store history
  if l:max == 0
    return
  endif

  " Remove duplicate if URL already exists in history
  let l:index = index(s:history, a:url)
  if l:index >= 0
    call remove(s:history, l:index)
  endif

  " Add URL to the front (latest first)
  call insert(s:history, a:url, 0)

  " Trim history to respect the maximum limit
  if len(s:history) > l:max
    let s:history = s:history[0:l:max - 1]
  endif
endfunction

" Get copy of history list
" @return list - Copy of history list (latest first)
function! vim_ppng#internal#history#get() abort
  return copy(s:history)
endfunction

" Clear all history
function! vim_ppng#internal#history#clear() abort
  let s:history = []
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

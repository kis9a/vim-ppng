scriptencoding utf-8

" Load guard
if exists('g:loaded_vim_ppng')
  finish
endif
let g:loaded_vim_ppng = 1

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Default options
if !exists('g:ppng_server')
  let g:ppng_server = 'https://ppng.io'
endif

if !exists('g:ppng_path')
  let g:ppng_path = 'random5char'
endif

if !exists('g:ppng_timeout')
  let g:ppng_timeout = 30
endif

if !exists('g:ppng_history_max')
  let g:ppng_history_max = 10
endif

" Commands

" PpngSend - Send text to ppng server
" Supports range for visual mode
" Optional path argument
command! -nargs=? -range PpngSend call s:send(<q-args>, <line1>, <line2>, <range>)

" PpngReceive - Receive text from ppng server
" Optional path argument
command! -nargs=? PpngReceive call vim_ppng#command#receive(<q-args>)

" PpngHistory - Show and interact with history
command! PpngHistory call vim_ppng#command#history()

" PpngClearHistory - Clear history
command! PpngClearHistory call vim_ppng#command#clear_history()

" Helper function for PpngSend to detect visual mode
function! s:send(args, line1, line2, range) abort
  " Check if range was provided (visual mode or line range)
  let l:is_visual = a:range == 2
  call vim_ppng#command#send(a:args, a:line1, a:line2, l:is_visual)
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

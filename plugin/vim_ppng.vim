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

" Encrypt :PpngSend / decrypt :PpngReceive even without '!'
if !exists('g:ppng_encrypt')
  let g:ppng_encrypt = 0
endif

" cryptmethod for encrypted sending; '' = xchacha20v2 with +sodium,
" else blowfish2
if !exists('g:ppng_cryptmethod')
  let g:ppng_cryptmethod = ''
endif

" Commands

" PpngSend - Send text to ppng server
" Supports range for visual mode
" Optional path argument
" With ! the text is encrypted with Vim's :X before sending
command! -bang -nargs=? -range PpngSend call s:send(<q-args>, <line1>, <line2>, <range>, <bang>0)

" PpngReceive - Receive text from ppng server
" Optional path argument
" With ! the received data is decrypted
command! -bang -nargs=? PpngReceive call vim_ppng#command#receive(<q-args>, <bang>0 ? 1 : -1)

" PpngHistory - Show and interact with history
command! PpngHistory call vim_ppng#command#history()

" PpngClearHistory - Clear history
command! PpngClearHistory call vim_ppng#command#clear_history()

" Helper function for PpngSend to detect visual mode
function! s:send(args, line1, line2, range, bang) abort
  " Check if range was provided (visual mode or line range)
  let l:is_visual = a:range == 2
  call vim_ppng#command#send(a:args, a:line1, a:line2, l:is_visual, a:bang ? 1 : -1)
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

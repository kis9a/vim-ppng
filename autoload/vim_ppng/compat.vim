scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Check if Neovim is running
function! vim_ppng#compat#has_nvim() abort
  return has('nvim')
endfunction

" Notify message with level
" @param msg string - Message to display
" @param level string - Level: 'info' | 'warn' | 'error'
function! vim_ppng#compat#notify(msg, level) abort
  if exists('*nvim_notify')
    " Map level string to nvim log level
    " 1 = INFO, 2 = WARN, 3 = ERROR
    let l:log_level = 1
    if a:level ==# 'error'
      let l:log_level = 3
    elseif a:level ==# 'warn'
      let l:log_level = 2
    elseif a:level ==# 'info'
      let l:log_level = 1
    endif
    call nvim_notify(a:msg, l:log_level, {})
  else
    " Fallback to standard Vim echo commands
    if a:level ==# 'error'
      echoerr a:msg
    else
      echomsg a:msg
    endif
  endif
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

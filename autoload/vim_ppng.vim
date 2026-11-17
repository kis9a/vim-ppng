scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Public API: Send text to ppng server
" @param mode string - 'normal' or 'visual'
" @param path string - Path/URL or empty string for prompt
" @param ... dict - options: {'encrypt': v:true/v:false}
"                   (omitted key = follow g:ppng_encrypt)
" @return dict - {'ok': v:true/v:false, 'url': '...', 'error': ''}
function! vim_ppng#send(mode, path, ...) abort
  let l:encrypt = s:encrypt_flag(a:0 ? a:1 : {})
  let l:range_start = 1
  let l:range_end = line('$')
  let l:is_visual = v:false

  " Handle visual mode - get visual range
  if a:mode ==# 'visual'
    let l:is_visual = v:true
    let l:start_pos = getpos("'<")
    let l:end_pos = getpos("'>")
    let l:range_start = l:start_pos[1]
    let l:range_end = l:end_pos[1]
  endif

  " Call underlying command function
  let l:result = vim_ppng#command#send(a:path, l:range_start, l:range_end, l:is_visual, l:encrypt)

  " Transform result to match public API spec
  let l:url = ''
  let l:error = ''

  if l:result.ok && !empty(get(l:result, 'url', ''))
    let l:url = l:result.url
  elseif l:result.ok
    " Extract URL from the path argument or reconstruct it
    if !empty(a:path)
      let l:url = vim_ppng#core#resolve_url(a:path)
    else
      " URL should be in g:ppng_path after command#send
      if exists('g:ppng_path')
        let l:url = vim_ppng#core#resolve_url(g:ppng_path)
      endif
    endif
  else
    " Extract error message from stderr
    if !empty(l:result.stderr)
      let l:error = join(l:result.stderr, ' ')
    else
      let l:error = 'Unknown error'
    endif
  endif

  return {
        \ 'ok': l:result.ok,
        \ 'url': l:url,
        \ 'error': l:error
        \ }
endfunction

" Public API: Receive text from ppng server
" @param path string - Path/URL or empty string for prompt
" @param ... dict - options: {'encrypt': v:true/v:false}
"                   (omitted key = follow g:ppng_encrypt)
" @return dict - {'ok': v:true/v:false, 'url': '...', 'error': ''}
function! vim_ppng#receive(path, ...) abort
  " Call underlying command function
  let l:result = vim_ppng#command#receive(a:path, s:encrypt_flag(a:0 ? a:1 : {}))

  " Transform result to match public API spec
  let l:url = ''
  let l:error = ''

  if l:result.ok && !empty(get(l:result, 'url', ''))
    let l:url = l:result.url
  elseif l:result.ok
    " Extract URL from the path argument or reconstruct it
    if !empty(a:path)
      let l:url = vim_ppng#core#resolve_url(a:path)
    else
      " URL should be in g:ppng_path after command#receive
      if exists('g:ppng_path')
        let l:url = vim_ppng#core#resolve_url(g:ppng_path)
      endif
    endif
  else
    " Extract error message from stderr
    if !empty(l:result.stderr)
      let l:error = join(l:result.stderr, ' ')
    else
      let l:error = 'Unknown error'
    endif
  endif

  return {
        \ 'ok': l:result.ok,
        \ 'url': l:url,
        \ 'error': l:error
        \ }
endfunction

" @param opts dict
" @return number - 1 / 0, or -1 to follow g:ppng_encrypt
function! s:encrypt_flag(opts) abort
  if type(a:opts) != v:t_dict || !has_key(a:opts, 'encrypt')
    return -1
  endif
  return a:opts.encrypt ? 1 : 0
endfunction

" Public API: Clear history
function! vim_ppng#clear_history() abort
  call vim_ppng#internal#history#clear()
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

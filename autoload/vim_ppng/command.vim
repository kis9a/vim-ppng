scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Send text to ppng server
" @param args string - Optional path argument
" @param range_start number - Start line of range
" @param range_end number - End line of range
" @param is_visual boolean - Whether invoked from visual mode
" @param ... number - encrypt: 1 = encrypt, 0 = plain,
"                     -1 or omitted = follow g:ppng_encrypt
" @return dict - Result from curl_upload (plus 'url' when known)
function! vim_ppng#command#send(args, range_start, range_end, is_visual, ...) abort
  let l:encrypt = s:want_encrypt(a:0 ? a:1 : -1)

  " Refuse early (before any prompt) when this editor cannot encrypt
  if l:encrypt
    let l:method = vim_ppng#internal#crypt#method()
    let l:err = vim_ppng#internal#crypt#check(l:method)
    if !empty(l:err)
      return s:fail_send(s:error(l:err))
    endif
  endif

  let l:target = s:resolve_path(a:args, v:true)
  if l:target.canceled
    return s:canceled()
  endif
  if !empty(l:target.error)
    return s:fail_send(s:error(l:target.error))
  endif

  " Resolve URL from path
  let l:url = vim_ppng#core#resolve_url(l:target.path)

  " Get timeout from settings
  let l:timeout = get(g:, 'ppng_timeout', 30)

  if l:encrypt
    let l:lines = a:is_visual ? getline(a:range_start, a:range_end) : getline(1, '$')
    let l:result = s:send_encrypted(l:url, l:lines, l:timeout, l:method)
    if get(l:result, 'canceled', v:false)
      return s:canceled()
    endif
  else
    " Get text based on mode
    if a:is_visual
      let l:text = vim_ppng#core#get_text('visual', a:range_start, a:range_end)
    else
      let l:text = vim_ppng#core#get_text('normal', 0, 0)
    endif

    " The receiver needs a generated path before curl starts waiting
    if l:target.generated
      call s:waiting(l:url, '')
    endif

    " Upload text using curl
    let l:result = vim_ppng#deps#command#curl_upload(l:url, l:text, l:timeout)
  endif
  let l:result.url = l:url

  " Add to history if successful
  if l:result.ok
    call vim_ppng#internal#history#add(l:url)
  endif

  " Notify result
  if l:result.ok
    call vim_ppng#compat#notify((l:encrypt ? 'Sent encrypted to ' : 'Sent to ') . l:url, 'info')
  else
    return s:fail_send(l:result)
  endif

  return l:result
endfunction

" Receive text from ppng server
" @param args string - Optional path argument
" @param ... number - encrypt: 1 = decrypt, 0 = plain,
"                     -1 or omitted = follow g:ppng_encrypt
" @return dict - Result from curl_download (plus 'url' when known)
function! vim_ppng#command#receive(args, ...) abort
  let l:encrypt = s:want_encrypt(a:0 ? a:1 : -1)

  if l:encrypt
    let l:err = vim_ppng#internal#crypt#check('')
    if !empty(l:err)
      return s:fail_receive(s:error(substitute(l:err, 'Nothing was sent\.', 'Nothing was received.', '')))
    endif
  endif

  let l:target = s:resolve_path(a:args, v:false)
  if l:target.canceled
    return s:canceled()
  endif
  if !empty(l:target.error)
    return s:fail_receive(s:error(l:target.error))
  endif

  " Resolve URL from path
  let l:url = vim_ppng#core#resolve_url(l:target.path)

  " Get timeout from settings
  let l:timeout = get(g:, 'ppng_timeout', 30)

  if l:encrypt
    let l:result = s:receive_encrypted(l:url, l:timeout)
    if get(l:result, 'canceled', v:false)
      return s:canceled()
    endif
    let l:result.url = l:url
    if !l:result.ok
      return s:fail_receive(l:result)
    endif
    call s:open_buffer(l:result.lines)
    call remove(l:result, 'lines')
    call vim_ppng#internal#history#add(l:url)
    call vim_ppng#compat#notify('Received and decrypted from ' . l:url, 'info')
    return l:result
  endif

  " Download content using curl
  let l:result = vim_ppng#deps#command#curl_download(l:url, l:timeout)
  let l:result.url = l:url

  " If successful, create new buffer and insert content
  if l:result.ok
    " Create new buffer
    new

    " Set buffer options
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile

    " Get the text from stdout
    let l:text = join(l:result.stdout, "\n")

    " Insert received text - split with keepempty flag
    call setline(1, split(l:text, "\n", 1))

    " Remove trailing empty line if exists
    let l:last_line = line('$')
    if l:last_line > 1 && empty(getline(l:last_line))
      execute l:last_line . 'delete _'
    endif

    " Move cursor to top
    normal! gg

    " Add to history
    call vim_ppng#internal#history#add(l:url)

    " Notify success
    call vim_ppng#compat#notify('Received from ' . l:url, 'info')
  else
    return s:fail_receive(l:result)
  endif

  return l:result
endfunction

" Show and interact with history
function! vim_ppng#command#history() abort
  " Get history list
  let l:history = vim_ppng#internal#history#get()

  " Check if history is empty
  if empty(l:history)
    call vim_ppng#compat#notify('No history', 'info')
    return
  endif

  " Prepare list for inputlist - add header
  let l:list = ['Select history entry:']

  " Add each history entry with number (latest first)
  let l:idx = 1
  for l:url in l:history
    call add(l:list, l:idx . '. ' . l:url)
    let l:idx += 1
  endfor

  " Show list and get selection
  let l:choice = inputlist(l:list)

  " Validate selection
  if l:choice < 1 || l:choice > len(l:history)
    call vim_ppng#compat#notify('Invalid selection', 'warn')
    return
  endif

  " Get selected URL
  let l:selected_url = l:history[l:choice - 1]

  " Ask whether to send or receive
  let l:action_list = [
        \ 'Select action for ' . l:selected_url . ':',
        \ '1. Send',
        \ '2. Receive',
        \ '3. Send encrypted',
        \ '4. Receive encrypted'
        \ ]
  let l:action_choice = inputlist(l:action_list)

  " Execute action
  if l:action_choice == 1
    " Send - use current buffer
    call vim_ppng#command#send(l:selected_url, 1, line('$'), v:false, 0)
  elseif l:action_choice == 2
    " Receive
    call vim_ppng#command#receive(l:selected_url, 0)
  elseif l:action_choice == 3
    call vim_ppng#command#send(l:selected_url, 1, line('$'), v:false, 1)
  elseif l:action_choice == 4
    call vim_ppng#command#receive(l:selected_url, 1)
  else
    call vim_ppng#compat#notify('Invalid action', 'warn')
  endif
endfunction

" Clear history
function! vim_ppng#command#clear_history() abort
  " Clear history
  call vim_ppng#internal#history#clear()

  " Notify user
  call vim_ppng#compat#notify('History cleared', 'info')
endfunction

" ---------------------------------------------------------------------------
" Helpers

" @param flag number - 1, 0, or -1 (follow g:ppng_encrypt)
function! s:want_encrypt(flag) abort
  if a:flag is v:true || (type(a:flag) == v:t_number && a:flag > 0)
    return v:true
  endif
  if a:flag is v:false || (type(a:flag) == v:t_number && a:flag == 0)
    return v:false
  endif
  return get(g:, 'ppng_encrypt', 0) ? v:true : v:false
endfunction

" Get the path from the argument or a prompt.
" The token {random} (as argument, or as g:ppng_path for the send prompt)
" becomes a fresh random path.
" @return dict - {'path', 'generated', 'canceled', 'error'}
function! s:resolve_path(args, for_send) abort
  let l:ret = {'path': trim(a:args), 'generated': v:false, 'canceled': v:false, 'error': ''}

  " If no args provided, prompt for path
  if empty(l:ret.path)
    let l:configured = get(g:, 'ppng_path', '')
    let l:keep_token = vim_ppng#core#is_random_token(l:configured)
    let l:default = l:configured
    if l:keep_token
      let l:default = a:for_send ? vim_ppng#core#random_path() : ''
    endif
    let l:ret.path = vim_ppng#core#prompt_for_path(l:default)

    " If user canceled (empty input), abort
    if empty(l:ret.path)
      let l:ret.canceled = v:true
      return l:ret
    endif

    let l:ret.generated = l:keep_token && a:for_send && l:ret.path ==# l:default

    " Update g:ppng_path with user input (keep the {random} token)
    if !l:keep_token
      let g:ppng_path = l:ret.path
    endif
  endif

  if vim_ppng#core#is_random_token(l:ret.path)
    if !a:for_send
      let l:ret.error = 'Cannot receive from {random}; enter the path the sender shows'
      return l:ret
    endif
    let l:ret.path = vim_ppng#core#random_path()
    let l:ret.generated = v:true
  endif
  return l:ret
endfunction

" Encrypt lines into a 0600 temp file and upload it.
" The temp file is removed and the key dropped even when something fails.
function! s:send_encrypted(url, lines, timeout, method) abort
  let l:key = vim_ppng#core#prompt_secret('Ppng key: ')
  if empty(l:key)
    return {'canceled': v:true}
  endif
  let l:again = vim_ppng#core#prompt_secret('Ppng key (again): ')
  if l:again !=# l:key
    let l:key = ''
    let l:again = ''
    return s:error('Keys do not match. Nothing was sent.')
  endif
  let l:again = ''

  let l:file = vim_ppng#internal#crypt#tempfile()
  if empty(l:file)
    let l:key = ''
    return s:error('Cannot create a private temp file. Nothing was sent.')
  endif
  try
    let l:err = vim_ppng#internal#crypt#write(l:file,
          \ vim_ppng#internal#crypt#pack(a:lines), l:key, a:method)
    let l:key = ''
    if !empty(l:err)
      return s:error(l:err . ' Nothing was sent.')
    endif
    call s:waiting(a:url, a:method)
    return vim_ppng#deps#command#curl_upload_file(a:url, l:file, a:timeout)
  finally
    let l:key = ''
    call delete(l:file)
  endtry
endfunction

" Download into a 0600 temp file and decrypt it.
" @return dict - curl result plus 'lines' on success
function! s:receive_encrypted(url, timeout) abort
  " Ask before downloading: the server holds the connection until a sender
  let l:key = vim_ppng#core#prompt_secret('Ppng key: ')
  if empty(l:key)
    return {'canceled': v:true}
  endif

  let l:file = vim_ppng#internal#crypt#tempfile()
  if empty(l:file)
    let l:key = ''
    return s:error('Cannot create a private temp file. Nothing was received.')
  endif
  try
    let l:result = vim_ppng#deps#command#curl_download_file(a:url, l:file, a:timeout)
    if !l:result.ok
      return l:result
    endif
    let l:dec = vim_ppng#internal#crypt#read(l:file, l:key)
    let l:key = ''
    if !l:dec.ok
      return s:error(l:dec.error)
    endif
    let l:result.lines = l:dec.lines
    return l:result
  finally
    let l:key = ''
    call delete(l:file)
  endtry
endfunction

" Open decrypted lines in a scratch buffer (no swap, no undo file)
function! s:open_buffer(lines) abort
  new
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal noundofile
  call setline(1, a:lines)
  setlocal nomodified
  normal! gg
endfunction

" Show the URL before curl blocks waiting for the receiver
function! s:waiting(url, method) abort
  redraw
  echomsg 'Waiting for receiver at ' . a:url
        \ . (empty(a:method) ? '' : ' (encrypted, ' . a:method . ')')
endfunction

function! s:error(msg) abort
  return {'ok': v:false, 'code': -1, 'stdout': [], 'stderr': [a:msg]}
endfunction

function! s:canceled() abort
  call vim_ppng#compat#notify('Canceled', 'info')
  return {'ok': v:false, 'code': -1, 'stdout': [], 'stderr': ['Canceled by user']}
endfunction

function! s:fail_send(result) abort
  call vim_ppng#compat#notify('Failed to send: ' . join(a:result.stderr, ' '), 'error')
  return a:result
endfunction

function! s:fail_receive(result) abort
  call vim_ppng#compat#notify('Failed to receive: ' . join(a:result.stderr, ' '), 'error')
  return a:result
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

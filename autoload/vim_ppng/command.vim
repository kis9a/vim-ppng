scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Send text to ppng server
" @param args string - Optional path argument
" @param range_start number - Start line of range
" @param range_end number - End line of range
" @param is_visual boolean - Whether invoked from visual mode
" @return dict - Result from curl_upload
function! vim_ppng#command#send(args, range_start, range_end, is_visual) abort
  " Parse args - trim whitespace
  let l:path = trim(a:args)

  " If no args provided, prompt for path
  if empty(l:path)
    let l:default = get(g:, 'ppng_path', '')
    let l:path = vim_ppng#core#prompt_for_path(l:default)

    " If user canceled (empty input), abort
    if empty(l:path)
      call vim_ppng#compat#notify('Canceled', 'info')
      return {'ok': v:false, 'code': -1, 'stdout': [], 'stderr': ['Canceled by user']}
    endif

    " Update g:ppng_path with user input
    let g:ppng_path = l:path
  endif

  " Resolve URL from path
  let l:url = vim_ppng#core#resolve_url(l:path)

  " Get text based on mode
  if a:is_visual
    let l:text = vim_ppng#core#get_text('visual', a:range_start, a:range_end)
  else
    let l:text = vim_ppng#core#get_text('normal', 0, 0)
  endif

  " Get timeout from settings
  let l:timeout = get(g:, 'ppng_timeout', 30)

  " Upload text using curl
  let l:result = vim_ppng#deps#command#curl_upload(l:url, l:text, l:timeout)

  " Add to history if successful
  if l:result.ok
    call vim_ppng#internal#history#add(l:url)
  endif

  " Notify result
  if l:result.ok
    call vim_ppng#compat#notify('Sent to ' . l:url, 'info')
  else
    let l:error_msg = 'Failed to send: ' . join(l:result.stderr, ' ')
    call vim_ppng#compat#notify(l:error_msg, 'error')
  endif

  return l:result
endfunction

" Receive text from ppng server
" @param args string - Optional path argument
" @return dict - Result from curl_download
function! vim_ppng#command#receive(args) abort
  " Parse args - trim whitespace
  let l:path = trim(a:args)

  " If no args provided, prompt for path
  if empty(l:path)
    let l:default = get(g:, 'ppng_path', '')
    let l:path = vim_ppng#core#prompt_for_path(l:default)

    " If user canceled (empty input), abort
    if empty(l:path)
      call vim_ppng#compat#notify('Canceled', 'info')
      return {'ok': v:false, 'code': -1, 'stdout': [], 'stderr': ['Canceled by user']}
    endif

    " Update g:ppng_path with user input
    let g:ppng_path = l:path
  endif

  " Resolve URL from path
  let l:url = vim_ppng#core#resolve_url(l:path)

  " Get timeout from settings
  let l:timeout = get(g:, 'ppng_timeout', 30)

  " Download content using curl
  let l:result = vim_ppng#deps#command#curl_download(l:url, l:timeout)

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
    " Notify error
    let l:error_msg = 'Failed to receive: ' . join(l:result.stderr, ' ')
    call vim_ppng#compat#notify(l:error_msg, 'error')
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
        \ '2. Receive'
        \ ]
  let l:action_choice = inputlist(l:action_list)

  " Execute action
  if l:action_choice == 1
    " Send - use current buffer
    call vim_ppng#command#send(l:selected_url, 1, line('$'), v:false)
  elseif l:action_choice == 2
    " Receive
    call vim_ppng#command#receive(l:selected_url)
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

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

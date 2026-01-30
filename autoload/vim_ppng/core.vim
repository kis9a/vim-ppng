scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Resolve URL from input
" @param input string - Either a full URL or a path
" @return string - Full URL
function! vim_ppng#core#resolve_url(input) abort
  " Check if input is already a full URL
  if a:input =~# '^\(http://\|https://\)'
    return a:input
  endif

  " Get the ppng server URL
  let l:server = get(g:, 'ppng_server', 'https://ppng.io')

  " Strip trailing slashes from server
  let l:server = substitute(l:server, '/\+$', '', '')

  " Strip leading slashes from path
  let l:path = substitute(a:input, '^/\+', '', '')

  " Combine server and path
  return l:server . '/' . l:path
endfunction

" Get text from buffer
" @param mode string - 'normal' or 'visual'
" @param start_line number - Start line number (for visual mode)
" @param end_line number - End line number (for visual mode)
" @return string - Text content with newlines
function! vim_ppng#core#get_text(mode, start_line, end_line) abort
  if a:mode ==# 'normal'
    " Get all lines from the buffer
    let l:lines = getline(1, '$')
  elseif a:mode ==# 'visual'
    " Get lines from start_line to end_line
    let l:lines = getline(a:start_line, a:end_line)
  else
    " Invalid mode, return empty string
    return ''
  endif

  " Join lines with newlines
  return join(l:lines, "\n")
endfunction

" Prompt user for path or URL
" @param default_value string - Default value to show in prompt
" @return string - User input or empty string if canceled
function! vim_ppng#core#prompt_for_path(default_value) abort
  let l:prompt = 'Ppng path or URL: '

  " Use mock if provided (for testing)
  if exists('g:Vim_ppng_input_mock')
    return g:Vim_ppng_input_mock
  endif

  " Try to get user input with default value
  try
    let l:user_input = input(l:prompt, a:default_value)
    return l:user_input
  catch
    " If input fails, return empty string
    return ''
  endtry
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

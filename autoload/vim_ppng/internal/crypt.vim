scriptencoding utf-8

" Save cpoptions
let s:save_cpo = &cpoptions
set cpoptions&vim

" Encryption layer built on Vim's own file encryption (:X, 'cryptmethod').
"
" The plain text is wrapped with one header line before it is encrypted:
"
"   vim-ppng-crypt:1:{line count}:{sha256 of the lines joined with "\n"}
"
" xchacha20v2 refuses a wrong key by itself, but blowfish2 silently returns
" garbage.  The header lets the receiver detect a wrong key (or truncated
" data) for every method and refuse to show anything.

let s:HEADER_PREFIX = 'vim-ppng-crypt:1:'
let s:HEADER_RE = '^vim-ppng-crypt:1:\(\d\+\):\(\x\{64}\)$'

" Methods vim-ppng will write and accept.  Order matters only for the error
" message.  'xchacha20' (v1) is obsolete according to :help 'cryptmethod'.
let s:SEND_METHODS = ['xchacha20v2', 'blowfish2']

" Magic bytes at the start of a file written by Vim with 'key' set.
let s:MAGIC = {
      \ 'VimCrypt~01!': 'zip',
      \ 'VimCrypt~02!': 'blowfish',
      \ 'VimCrypt~03!': 'blowfish2',
      \ 'VimCrypt~04!': 'xchacha20',
      \ 'VimCrypt~05!': 'xchacha20v2',
      \ }

let s:WRONG_KEY = 'Wrong key or corrupted data'

" Resolve the cryptmethod to use for sending.
" g:ppng_cryptmethod empty means: xchacha20v2 with +sodium, else blowfish2.
" @return string
function! vim_ppng#internal#crypt#method() abort
  let l:method = get(g:, 'ppng_cryptmethod', '')
  if !empty(l:method)
    return l:method
  endif
  return vim_ppng#compat#has('sodium') ? 'xchacha20v2' : 'blowfish2'
endfunction

" Check that this editor can encrypt/decrypt with {method}.
" @param method string - cryptmethod, or '' to check only for :X support
" @return string - error message, '' when usable
function! vim_ppng#internal#crypt#check(method) abort
  if vim_ppng#compat#has('nvim')
    return 'Encryption needs Vim''s :X and ''cryptmethod''; Neovim does not have them. Nothing was sent.'
  endif
  if !vim_ppng#compat#has('cryptv')
    return 'Encryption needs Vim built with +cryptv. Nothing was sent.'
  endif
  if empty(a:method)
    return ''
  endif
  if index(s:SEND_METHODS, a:method) < 0
    return 'Unsupported cryptmethod "' . a:method . '" (use one of: '
          \ . join(s:SEND_METHODS, ', ') . '). Nothing was sent.'
  endif
  if a:method ==# 'xchacha20v2' && !vim_ppng#compat#has('sodium')
    return 'cryptmethod ' . a:method . ' needs Vim built with +sodium'
          \ . ' (or set g:ppng_cryptmethod = ''blowfish2''). Nothing was sent.'
  endif
  return ''
endfunction

" Wrap lines with the integrity header.
" @param lines list - plain text lines
" @return list
function! vim_ppng#internal#crypt#pack(lines) abort
  let l:header = s:HEADER_PREFIX . len(a:lines) . ':' . sha256(join(a:lines, "\n"))
  return [l:header] + a:lines
endfunction

" Remove and verify the integrity header.
" @param lines list - decrypted lines
" @return dict - {'ok': bool, 'lines': list, 'error': string}
function! vim_ppng#internal#crypt#unpack(lines) abort
  let l:bad = {'ok': v:false, 'lines': [], 'error': s:WRONG_KEY}
  if empty(a:lines)
    return l:bad
  endif
  let l:m = matchlist(a:lines[0], s:HEADER_RE)
  if empty(l:m)
    return l:bad
  endif
  let l:count = str2nr(l:m[1])
  if len(a:lines) - 1 < l:count
    return l:bad
  endif
  let l:body = l:count == 0 ? [] : a:lines[1 : l:count]
  " Only empty lines may follow the counted body (end-of-file newline).
  for l:rest in a:lines[l:count + 1 :]
    if !empty(l:rest)
      return l:bad
    endif
  endfor
  if sha256(join(l:body, "\n")) !=# l:m[2]
    return l:bad
  endif
  return {'ok': v:true, 'lines': l:body, 'error': ''}
endfunction

" Detect the cryptmethod of a file from its magic bytes.
" @param file string
" @return string - method name, or '' when the file is not Vim-encrypted
function! vim_ppng#internal#crypt#detect(file) abort
  try
    let l:first = readfile(a:file, 'b', 1)
  catch
    return ''
  endtry
  if empty(l:first)
    return ''
  endif
  return get(s:MAGIC, strpart(l:first[0], 0, 12), '')
endfunction

" Create an empty temp file readable only by the owner.
" @return string - path ('' on failure)
function! vim_ppng#internal#crypt#tempfile() abort
  let l:file = tempname()
  if writefile([], l:file, 'b') != 0
    return ''
  endif
  call setfperm(l:file, 'rw-------')
  if getfperm(l:file) !=# 'rw-------'
    call delete(l:file)
    return ''
  endif
  return l:file
endfunction

" Encrypt lines into an existing file with Vim's own :write.
" The scratch buffer has no swap file and no undo, autocommands are skipped,
" and 'key' is cleared before the buffer is wiped.
" @param file string - target file (already created with 0600)
" @param lines list - lines to write (already packed)
" @param key string
" @param method string - cryptmethod
" @return string - error message, '' on success
function! vim_ppng#internal#crypt#write(file, lines, key, method) abort
  let l:err = ''
  let l:winid = win_getid()
  let l:bufnr = -1
  let l:save_backup = &backup
  let l:save_writebackup = &writebackup
  let l:save_cpo = &cpoptions
  try
    " Without 'a'/'A', :read/:write do not add the temp file to the buffer list
    noautocmd set cpoptions-=a cpoptions-=A
    noautocmd keepalt keepjumps silent new
    let l:bufnr = bufnr('%')
    setlocal noswapfile undolevels=-1 noundofile bufhidden=wipe nobuflisted
    setlocal fileformat=unix fileencoding=utf-8 nobomb nobinary
    call setline(1, a:lines)
    noautocmd let &l:cryptmethod = a:method
    noautocmd let &l:key = a:key
    " Write in place so the 0600 file keeps its mode and no backup is left.
    noautocmd set nobackup nowritebackup
    execute 'noautocmd keepalt silent write! ++ff=unix ' . fnameescape(a:file)
  catch
    let l:err = 'Encryption failed: ' . substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
  finally
    noautocmd let &backup = l:save_backup
    noautocmd let &writebackup = l:save_writebackup
    noautocmd let &cpoptions = l:save_cpo
    call s:wipe(l:bufnr)
    call s:wipe_file(a:file)
    call win_gotoid(l:winid)
  endtry
  if empty(l:err) && getfperm(a:file) !=# 'rw-------'
    call setfperm(a:file, 'rw-------')
  endif
  if empty(l:err) && vim_ppng#internal#crypt#detect(a:file) !=# a:method
    let l:err = 'Encryption failed: the written file is not encrypted with ' . a:method
  endif
  return l:err
endfunction

" Decrypt a file with Vim's own :read and verify the header.
" @param file string
" @param key string
" @return dict - {'ok': bool, 'lines': list, 'error': string}
function! vim_ppng#internal#crypt#read(file, key) abort
  let l:method = vim_ppng#internal#crypt#detect(a:file)
  if empty(l:method)
    return {'ok': v:false, 'lines': [],
          \ 'error': 'Received data is not encrypted (no VimCrypt header); not shown'}
  endif
  if index(s:SEND_METHODS, l:method) < 0
    return {'ok': v:false, 'lines': [],
          \ 'error': 'Received data uses the weak cryptmethod ' . l:method . '; not shown'}
  endif
  let l:err = vim_ppng#internal#crypt#check(l:method)
  if !empty(l:err)
    return {'ok': v:false, 'lines': [], 'error': substitute(l:err, ' Nothing was sent\.$', '', '')}
  endif

  let l:lines = []
  let l:err = ''
  let l:winid = win_getid()
  let l:bufnr = -1
  let l:save_cpo = &cpoptions
  try
    noautocmd set cpoptions-=a cpoptions-=A
    noautocmd keepalt keepjumps silent new
    let l:bufnr = bufnr('%')
    setlocal buftype=nofile noswapfile undolevels=-1 noundofile bufhidden=wipe nobuflisted
    " With 'key' set, :read decrypts without prompting.
    noautocmd let &l:key = a:key
    execute 'noautocmd keepalt silent 0read ++ff=unix ++enc=utf-8 ' . fnameescape(a:file)
    let l:lines = getline(1, '$')
  catch /E1200:/
    let l:err = s:WRONG_KEY
  catch
    let l:err = 'Decryption failed: ' . substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
  finally
    noautocmd let &cpoptions = l:save_cpo
    call s:wipe(l:bufnr)
    call s:wipe_file(a:file)
    call win_gotoid(l:winid)
  endtry
  if !empty(l:err)
    return {'ok': v:false, 'lines': [], 'error': l:err}
  endif
  return vim_ppng#internal#crypt#unpack(l:lines)
endfunction

" Clear 'key' and wipe a scratch buffer.
function! s:wipe(bufnr) abort
  if a:bufnr < 0 || !bufexists(a:bufnr)
    return
  endif
  noautocmd call setbufvar(a:bufnr, '&key', '')
  execute 'noautocmd silent! bwipeout! ' . a:bufnr
endfunction

" Wipe any buffer that refers to {file} (e.g. an alternate-file entry).
function! s:wipe_file(file) abort
  let l:target = resolve(fnamemodify(a:file, ':p'))
  for l:info in getbufinfo()
    if !empty(l:info.name) && resolve(fnamemodify(l:info.name, ':p')) ==# l:target
      call s:wipe(l:info.bufnr)
    endif
  endfor
endfunction

" Restore cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

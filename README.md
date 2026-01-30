# vim-ppng

Share text instantly between Vim/Neovim instances via [Ppng Server](https://ppng.io).

## Overview

vim-ppng enables real-time text sharing between editors using Ppng Server. Send buffer content or visual selections from one editor and receive them in another with simple commands.

## Requirements

- Vim: 8.0 or later
- Neovim: 0.5 or later
- curl: Required for HTTP communication

## Installation

### Using vim-plug

```vim
Plug 'kis9a/vim-ppng'
```

### Using dein.vim

```vim
call dein#add('kis9a/vim-ppng')
```

### Using packer.nvim (Neovim)

```lua
use 'kis9a/vim-ppng'
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/kis9a/vim-ppng.git
```

2. Copy the plugin files to your Vim runtime directory:
```bash
# For Vim
cp -r vim-ppng/* ~/.vim/

# For Neovim
cp -r vim-ppng/* ~/.config/nvim/
```

3. Generate help tags:
```vim
:helptags ~/.vim/doc  " For Vim
:helptags ~/.config/nvim/doc  " For Neovim
```

## Features

### Commands

- `:PpngSend [path]` - Send buffer content or visual selection to Ppng Server
- `:PpngReceive [path]` - Receive text from Ppng Server into a new buffer
- `:PpngHistory` - Show and interact with recently used URLs
- `:PpngClearHistory` - Clear history

### Functions

Public API for programmatic access:

- `vim_ppng#send(mode, path)` - Send text (mode: 'normal' or 'visual')
- `vim_ppng#receive(path)` - Receive text from server
- `vim_ppng#clear_history()` - Clear history

### Options

- `g:ppng_server` - Base URL of Ppng Server (default: `'https://ppng.io'`)
- `g:ppng_path` - Default path (default: `'random5char'`)
- `g:ppng_timeout` - Timeout in seconds (default: `30`)
- `g:ppng_history_max` - Maximum history entries (default: `10`)

## Configuration

Add to your `.vimrc` or `init.vim`:

```vim
" Custom Ppng Server (optional)
let g:ppng_server = 'https://ppng.io'

" Default path
let g:ppng_path = 'random5char'

" Timeout for curl operations (in seconds)
let g:ppng_timeout = 30

" Maximum number of history entries
let g:ppng_history_max = 10
```

### Key Mappings (Example)

vim-ppng does not define default key mappings. Add your preferred mappings to `.vimrc` or `init.vim`:

```vim
" Send entire buffer
nnoremap <Leader>ps :PpngSend<CR>

" Send visual selection
vnoremap <Leader>ps :PpngSend<CR>

" Receive from server
nnoremap <Leader>pr :PpngReceive<CR>

" Show history
nnoremap <Leader>ph :PpngHistory<CR>
```

## Usage

### Basic Example

**Editor A (Sender):**
```vim
:PpngSend mytext
" Entire buffer content is sent to https://ppng.io/mytext
```

**Editor B (Receiver):**
```vim
:PpngReceive mytext
" Content is received and displayed in a new buffer
```

### Visual Selection

Select text in visual mode and send:
```vim
" 1. Enter visual mode (v or V)
" 2. Select text
" 3. Run command
:'<,'>PpngSend shared
```

### Using History

After sending or receiving, access previous URLs:
```vim
:PpngHistory
" Select an entry and choose to send or receive
```

### Full URL Support

You can specify full URLs instead of paths:
```vim
:PpngSend https://ppng.io/custom-path
:PpngReceive https://ppng.io/custom-path
```

### Random Paths

Use `random5char` to let the server generate a random path:
```vim
let g:ppng_path = 'random5char'
:PpngSend
" Server will generate a random 5-character path
```

### Programmatic Usage

Use the public API in your Vimscript code:

```vim
" Send entire buffer
let result = vim_ppng#send('normal', 'mypath')
if result.ok
    echo 'Sent to: ' . result.url
else
    echoerr 'Error: ' . result.error
endif

" Receive from server
let result = vim_ppng#receive('mypath')
if result.ok
    echo 'Received from: ' . result.url
endif
```

## About Ppng Server

[Ppng Server](https://ppng.io) is a service that creates real-time data pipes using HTTP. When you send data to a path, the server holds the connection until someone requests from the same path, creating an instant transfer.

**Default server:** https://ppng.io

**Security Note:**
- Data is transferred in plain text
- Anyone with the URL can access the data
- Use random/unique paths for sensitive content
- Consider running your own Ppng Server for private use

**Self-hosting:**
You can run your own Ppng Server: https://github.com/nwtgck/ppng-server

## Testing

### Install Testing Dependencies

```bash
make deps
```

### Run Linter

```bash
make lint
```

### Run Tests

**Vim:**
```bash
THEMIS_VIM=vim THEMIS_ARGS='-Nu NONE -U NONE -i NONE -n' make test
```

**Neovim:**
```bash
THEMIS_VIM=nvim THEMIS_ARGS='--headless -u NONE -i NONE -n' make test
```

### Manual Testing

**Vim:**
```bash
vim -Nu NONE -U NONE -i NONE -n +'set rtp^=.' +'runtime plugin/vim_ppng.vim'
```

**Neovim:**
```bash
nvim -u NONE -i NONE -n +'set rtp^=.' +'runtime plugin/vim_ppng.vim'
```

## Development

### Architecture

The plugin follows the layered architecture pattern:

```
plugin/vim_ppng.vim          # Entry point: commands and options
autoload/vim_ppng.vim        # Public API
autoload/vim_ppng/
  ├── command.vim              # Command implementations
  ├── core.vim                 # Core logic
  ├── compat.vim               # Vim/Neovim compatibility layer
  ├── deps/
  │   └── command.vim          # External command (curl) wrapper
  └── internal/
      └── history.vim          # History management
```

## LICENSE

MIT License - See [LICENSE](LICENSE) file for details.

Copyright (c) 2026 @kis9a

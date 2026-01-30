# vim-ppng Test Suite

This directory contains the test suite for the vim-ppng plugin, written using vim-themis.

## Test Files

### 1. test/deps.vimspec
Tests the dependency layer (curl command wrappers) with stubs.

**Tests:**
- `vim_ppng#deps#command#curl_upload()` with stub
  - Success case
  - Failure case (timeout)
  - Parameter passing verification
  - Timeout value handling
  - Curl not found case (documented/skipped)

- `vim_ppng#deps#command#curl_download()` with stub
  - Success case with content
  - Failure case (host resolution error)
  - Parameter passing verification
  - Network timeout
  - Empty response handling

**Key Features:**
- Uses `g:Vim_ppng_curl_runner` stub for testing without actual curl calls
- Tests both success and failure scenarios
- Verifies parameter passing and timeout handling
- Properly cleans up global state after each test

### 2. test/basic.vimspec
Tests core functionality of the plugin.

**Tests:**
- `vim_ppng#core#resolve_url()` URL resolution
  - Full URLs (http/https) pass through unchanged
  - Path-only inputs combine with default server (https://ppng.io)
  - Custom server configuration via `g:ppng_server`
  - Trailing/leading slash handling
  - URL parameters and fragments preservation

- `vim_ppng#core#get_text()` text extraction
  - Normal mode: get all buffer text
  - Visual mode: get selected line range
  - Single line selection
  - First/last line handling
  - Empty buffer handling
  - Empty lines preservation
  - Invalid mode returns empty string

- `vim_ppng#core#prompt_for_path()` (documented only, requires user interaction)

**Key Features:**
- Tests buffer manipulation and text extraction
- Verifies URL resolution logic with various input formats
- Properly cleans up buffers and global state

### 3. test/history.vimspec
Tests history management functionality.

**Tests:**
- `vim_ppng#internal#history#add()` adding URLs
  - Basic URL addition
  - Multiple URL handling
  - Latest-first ordering
  - Duplicate URL detection (moves to front)
  - Size management does not increase on duplicates
  - Respects default max limit (10)
  - Custom max limit via `g:ppng_history_max`
  - Min limit of 1
  - Disabled history when max=0
  - Trimming when max is reduced
  - Consecutive duplicate handling
  - URLs with special characters

- `vim_ppng#internal#history#get()` retrieving history
  - Returns copy (not reference)
  - Empty history handling

- `vim_ppng#internal#history#clear()` clearing history
  - Complete history clear
  - Adding after clear

**Key Features:**
- Comprehensive coverage of history edge cases
- Tests max limit enforcement and dynamic changes
- Verifies copy semantics to prevent unintended modifications
- Tests disabled history mode (max=0)

## Running Tests

### Run All Tests
```bash
cd /Users/kis9a/dev/kis9a/vimplugin-cookbook/vim-ppng
.deps/vim-themis/bin/themis test/
```

### Run Individual Test Files
```bash
# Test deps layer
.deps/vim-themis/bin/themis test/deps.vimspec

# Test core functionality
.deps/vim-themis/bin/themis test/basic.vimspec

# Test history
.deps/vim-themis/bin/themis test/history.vimspec
```

## Test Results Summary

- **Total Tests:** 47
- **Passing:** 45
- **Pending/Skipped:** 2
  - curl not found case (requires executable() mocking)
  - prompt_for_path (requires user interaction)

## Test Structure

Tests follow vim-themis conventions:

- `Describe` blocks group related tests
- `It` blocks define individual test cases
- `Before all` / `After all` for suite-level setup/teardown
- `Before each` / `After each` for test-level setup/teardown
- Assertions: `Assert Equals`, `Assert True`, `Assert False`, `Assert Match`
- `Skip` for tests that cannot be automated

## Design Decisions

### Stub Pattern for curl Commands
The curl command functions check for `g:Vim_ppng_curl_runner` to enable testing without making actual network calls. This allows tests to:
- Run without network access
- Run deterministically
- Test error conditions easily
- Complete quickly

### Global Variables for Test State
Test verification uses global variables (e.g., `g:test_stub_received`) instead of script-local variables to share state between stub functions and test assertions, as required by VimScript's scoping rules.

### Cleanup After Each Test
All tests properly clean up:
- Global configuration variables
- Test stubs and state
- Buffers created during tests
- History state

This ensures test isolation and prevents side effects between tests.

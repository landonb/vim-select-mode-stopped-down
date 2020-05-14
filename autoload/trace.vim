" Simple trace function wrapper around echom, to help debug.
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Online: https://github.com/landonb/vim-select-mode-stopped-down
" License: https://creativecommons.org/publicdomain/zero/1.0/

" ========================================================================

" DEBUG: Use an `echom` log file to help you develop this plugin.

" NOTE: You can use either redir or verbosefile. The latter will not display
"   verbose messages, but we do not use the :verbose-cmd feature, so doesn't
"   matter which you choose. Also note that Vim will both display the messages
"   (to the Vim status line, and the :messages buffer) as well as write them
"   to the file, but the file buffer is not flushed immediately (next comment).
" CAVEAT: Note that both redir or verbose are buffered, so you won't see
"   tracing as it happens. Use <F9> in this file to source it again, which
"   calls redir or verbosefile again, which seems to flush the buffer.
" USAGE:
" - You could use redir:
"     redir >> /tmp/vim.echom
"   Then when done:
"     redir END
" - Or you could use verbosefile:
"     set verbosefile=/tmp/vim.echom
"   Then when done:
"     set verbosefile=
" YOU: Uncomment to enable log file tracing:
"
"  set verbosefile=/tmp/vim.echom

" ========================================================================

" Trace levels: 0 to disable. 1 to see shorter `echom` messages. 2 for all tracing.
let s:_trace_level = 0
" YOU: Uncomment to see trace messages.
"
"  let s:_trace_level = 1
"  let s:_trace_level = 2

function! trace#trace(msg)
  if s:_trace_level > 0
    echom a:msg
  endif
endfunction

function! trace#trace_level()
  return s:_trace_level
endfunction


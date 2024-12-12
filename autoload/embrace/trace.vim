" Simple trace function wrapper around echom, to help debug.
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/vim-select-mode-stopped-down#🛑
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

" USAGE: Uncomment to see trace messages. Or set yourself.
"
" let g:embrace_smsd_debug_level = 1

function! g:embrace#trace#trace(msg) abort
  if g:embrace#trace#trace_level()
    echom a:msg
  endif
endfunction

function! g:embrace#trace#trace_level() abort
  if !exists("g:embrace_smsd_debug_level")
    let g:embrace_smsd_debug_level = 0
  endif

  return g:embrace_smsd_debug_level
endfunction


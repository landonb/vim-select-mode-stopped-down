" Improved wordy select-mode behavior wire to ctrl-select-left/-right work.
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Online: https://github.com/landonb/vim-select-mode-stopped-down
" License: https://creativecommons.org/publicdomain/zero/1.0/
"
" " ========================================================================

" YOU: 1.) Uncomment the `let` to enable this feature; then
"      2.) Use <F9> to reload this script.
"      - HINT: <F9> defined by: landonb/dubs_ftype_mess or run:
"        noremap <silent><buffer> <F9> :exec 'source '.bufname('%')<CR>
"
"  let s:reloadable = 1
if exists("s:reloadable") && s:reloadable &&
    \ exists("g:loaded_vim_ctrl_left_right_word_motions")
  unlet g:loaded_vim_ctrl_left_right_word_motions
endif

" ***

if exists("g:loaded_vim_ctrl_left_right_word_motions") || &cp
  finish
endif
let g:loaded_vim_ctrl_left_right_word_motions = 1

" ========================================================================

function! s:forward_text_next_word(mode, curc)
  " If radjust set at end of function, nudges cursor one more right.
  let radjust = 0
  " HINTS: Use virtcol(), not col(), to account for Unicode/mutli-byte characters.
  "        Use getpos/setpos to restore cursor in case it jumps across lines, and
  "        not `[count]|` or similar.
  let vcol_curr = virtcol(".")
  let vcol_last = virtcol("$")

  let vcol_visi = s:get_leftmost_nonblank_virt_col()

  let trace_vars = "vcol_visi: " . l:vcol_visi
    \ . " / vcol_curr: " . l:vcol_curr
    \ . " / vcol_last: " . l:vcol_last

  if 1
    \ && ! s:forward_handle_if_on_empty_line(l:vcol_last, l:trace_vars)
    \ && ! s:forward_handle_if_in_leading_whitespace(l:vcol_curr, l:vcol_visi, l:trace_vars)
    \ && ! s:forward_handle_if_at_penultimate(a:mode, l:vcol_curr, l:vcol_last, l:trace_vars)
    \ && ! s:forward_handle_if_atop_single_char_line(a:mode, l:vcol_curr, l:vcol_last, l:trace_vars)
    \ && ! s:forward_handle_if_at_first_position(l:vcol_curr, l:trace_vars)
    " Otherwise, somewhere inside the line (from the first visible
    " character to the penultimate), or at the end of the line.
    let radjust = s:forward_move_cursor_from_col_inner_or_last(
      \ a:mode, l:vcol_curr, l:vcol_visi, l:trace_vars)
  endif

  if l:radjust == 1
    let [cp_zed0, cp_lnum, cp_coln, cp_zed1] = getpos('.')
    call setpos('.', [0, l:cp_lnum, l:cp_coln + 1, 0])
  endif
endfunction

" ***

function! s:get_leftmost_nonblank_virt_col()
  " Identify the leftmost column with a non-blank ┃character.
  let l:waspos = getpos(".")
  " - You can use ^ or _ to go to first character in line,
  "   but note that Dubs Vim maps `__`, so a single `_` is delayed.
  " - Also note `0` goes to first column, whereas `^` goes to first non-blank.
  normal! ^
  let vcol_visi = virtcol(".")
  " Return to original position.
  call setpos('.', l:waspos)
  return l:vcol_visi
endfunction

" ***

function! s:forward_handle_if_on_empty_line(vcol_last, trace_vars)
  if a:vcol_last != 1 | return 0 | endif

  call trace#trace("Empty line: " . a:trace_vars)
  call s:cursor_nudge_one_character_right()
  return 1
endfunction

function! s:cursor_nudge_one_character_right()
  let was_ww = &whichwrap
  set whichwrap=l
  normal! l
  execute "set whichwrap=" . l:was_ww
endfunction

" ***

function! s:forward_handle_if_in_leading_whitespace(vcol_curr, vcol_visi, trace_vars)
  if a:vcol_curr >= a:vcol_visi | return 0 | endif

  " The cursor is at or near the start of the line, with one or more whitespace
  " between it and the first character in the line. So jump to the first \< word
  " beginning (which is what ^ does).
  call trace#trace("Stop on first: " . a:trace_vars)
  normal! ^
  return 1
endfunction

" ***

function! s:forward_handle_if_at_penultimate(mode, vcol_curr, vcol_last, trace_vars)
  " - First consider if the cursor is at the penultimate position, i.e., one
  "   position before the end of the line (in which case just go to the end
  "   of the line, and avoid the more complicated logic that comes later).
  "   - Note that, in insert mode, the penultimate position is one before
  "     the last column index, e.g., in the following 11-character line:
  "       012 foo bar
  "                ^^
  "    If the insert mode cursor is between the 'a' and the 'r',
  "      virtcol(".") == 11, and virtcol("$") == 12.
  "     But if the normal mode cursor is atop the 'a', then
  "     virtcol(".") == 10, and virtcol("$") == 12.
  let penult_col = a:mode == 'i' ? (a:vcol_last - 1) : (a:vcol_last - 2)
  if a:vcol_curr != l:penult_col | return 0 | endif

  call trace#trace("At penult: vcol_curr: " . a:vcol_curr . " / vcol_last: " . a:vcol_last
    \ . " / " . a:trace_vars
    \)
  normal! $
  return 1
endfunction

" ***

function! s:forward_handle_if_atop_single_char_line(mode, vcol_curr, vcol_last, trace_vars)
  " Special case: Single-character line, and normal mode. Nudge cursor right, to next line.
  if a:mode != 'n' || a:vcol_last != 2 | return 0 | endif

  call s:cursor_nudge_one_character_right()
  return 1
endfunction

" ***

function! s:forward_handle_if_at_first_position(vcol_curr, trace_vars)
  " Cursor is neither on an empty line, nor before the first column of the
  " first visible character, nor in normal mode about a single-character
  " line, nor is it at the penultimate position.
  " - Check now if at the first column (in which case the line starts
  "   with a visible character, and we need to check if it's just one
  "   character wide, or wider).
  if a:vcol_curr != 1 | return 0 | endif

  call s:forward_move_cursor_from_first_postition(a:trace_vars)
  return 1
endfunction

function! s:forward_move_cursor_from_first_postition(trace_vars)
  " Special case: First word in line starts in column 1 and is 1 character
  " long, and cursor is before the first word (between ^ and first character).
  " - If we simply 'e', the cursor jumps past the end of first word to the end
  "   of second word. This ensures cursor jumps from before single-character
  "   word at column 1 to after single-character word, to column 2.
  " - Also, avoid running `h` from first column without enabling whichwrap, or
  "   Vim alerts via inverse screen toggle (could probably call anyway and use
  "   `silent`, but this is more readable).

  " Get character (not byte) at first postition.
  let char_0 = strgetchar(getline('.'), 0)
  " Also determine the character size, to position the cursor properly.
  let nbytes = strlen(nr2char(l:char_0))
  call trace#trace("char_0: " . nr2char(l:char_0)
    \ . " (strlen: " . strlen(l:char_0) . " / nbytes: " . l:nbytes . ")"
    \ . " / " . a:trace_vars)

  " Temporary set whichwrap, which might otherwise default to:
  "   :echo &whichwrap
  "   set whichwrap=b,s,<,>,[,]
  "   set whichwrap=b,s,<,>,[,],h,l
  " so that the `h` is allowed to backup over the newline.
  let was_ww = &whichwrap
  set whichwrap=h
  normal! he
  execute "set whichwrap=" . l:was_ww
  let [cp_zed0, cp_lnum, cp_coln, cp_zed1] = getpos('.')
  call setpos('.', [0, l:cp_lnum, l:cp_coln + l:nbytes, 0])
endfunction

" ***

function! s:forward_move_cursor_from_col_inner_or_last(
  \ mode, vcol_curr, vcol_visi, trace_vars
\)
  let radjust = 0
  let audittrace = ""
  " See where cursor would be if we nudged it left and then ran `e`.
  let vcol_after_he = s:forward_text_suss_vcol_after_he()
  " Check for cases where we move right one character (using `l`):
  " - If an `he` jumps to the next line, walk across the newline
  "   (go 'right' one character), rather then using the `e` motion,
  "   which jumps past the first word on the next line.
  " - If an `he` ends up at the same cursor position, it means the
  "   cursor is either on top of the last character of a word (in
  "   normal mode), or it's in the penultimate position (between the
  "   final two characters, in insert mode). This is an edge case
  "   where `e` jumps too far, i.e., past the end of the next word.
  "   But we want to behave like we would if the cursor were at an
  "   early position in the word -- move the cursor to the end of
  "   the current word, not the next one.
  if l:vcol_after_he == -1
    if virtcol(".") < virtcol("$") - 1
      let audittrace = "Whitespace...$"
      normal! $
    else
      let audittrace = "Whitespace$"
      call s:cursor_nudge_one_character_right()
    endif
  elseif a:vcol_curr >= l:vcol_after_he
    " Normal 'e' behavior jumps from final column of some line to past first
    " word on next line. This instead uses <Right> to nudge cursor just over
    " newline.
    let audittrace = "Penult/end"
    call s:cursor_nudge_one_character_right()
  else
    " Otherwise, we can use `e` to jump past the next word. But we may
    " need to nudge the cursor further to the right one, to land *after*
    " the next word, as `e` lands on the *end* on the next word.
    normal! e
    let radjust = 1
    " Move <right> (or `l`), otherwise the cursor ends up between the last two
    " characters of the word when switching back from <C-O> to insert mode.
    if a:mode == 'i'
      if virtcol(".") < virtcol("$") - 1
        " The radjust will be applied by the caller.
        let audittrace = "Right/'i'"
      else
        " Jump to the end of the line.
        let audittrace = "To end/'i'"
        normal! $
      endif
    else
      let audittrace = "Right/'n'"
    endif
  endif

  call trace#trace(l:audittrace . ": "
    \ . " / vcol_after_he: " . l:vcol_after_he
    \ . " / virtcol('.'): " . virtcol(".")
    \ . " / virtcol('$'): " . virtcol("$")
    \ . " / " . a:trace_vars)

  return l:radjust
endfunction

" ***

function! s:forward_text_suss_vcol_after_he()
  " Caller handled case where cursor is in first column or
  " on empty line, so do not need to worry from the `h` backing
  " up to the previous line; but we do need to be aware that the
  " `e` might jump to the next line.
  let l:waspos = getpos(".")
  let l:wasline = l:waspos[1]
  normal! he
  if l:wasline == line('.')
    let vcol_after_he = virtcol(".")
  else
    let vcol_after_he = -1
  endif
  " Remember to use setpos(), and not [count]|.
  call setpos('.', l:waspos)
  return l:vcol_after_he
endfunction

" ========================================================================

function! s:free_keys_word_motions_leftward()
  nunmap <C-Left>
  iunmap <C-Left>
endfunction

function! s:free_keys_word_motions_rightward()
  nunmap <C-Right>
  iunmap <C-Right>
endfunction

function! s:free_keys_word_motions()
  " Clear any existing mappings (makes this file reentrant).
  call s:free_keys_word_motions_leftward()
  call s:free_keys_word_motions_rightward()
endfunction

function! s:wire_keys_word_motions_leftward()
  " MAYBE/2020-05-12: Make C-Left more like C-Right.
  " - Some quirks with using builtin `b`:
  "   - If there's a word on a line, two empty lines, and then the cursor
  "     at the start of a fourth line, a `b` will move the cursor up one
  "     line, to the third line. Another `b` moves cursor up one more line,
  "     and then a final `b` moves the cursor to the start of the first line,
  "     before the word. / However if you make the empty lines blank lines,
  "     e.g., one or more spaces, then `b` will jump the cursor from the
  "     fourth line to the start of the first line, before the word.
  "     - This is not a big deal to me, just a note that C-Left may appear
  "       inconsistent, because I have not over-engineered a motion function,
  "       like forward_text_next_word.
  nnoremap <C-Left> b
  inoremap <C-Left> <C-O>b
  " Don't vmap C-Left, or after C-S-Left it'll keep selecting without
  " Shift pressed anymore:
  "   vnoremap <C-Left> b
endfunction

function! s:wire_keys_word_motions_rightward()
  " Note that a simple `e` is not robust enough to implement the behavior
  " we want, so defer to a more complicated function.
  " - And, reminder: 'CTRL-U (<C-U>) removes the range that Vim may insert.'
  nnoremap <silent> <C-Right> :<C-U>call <SID>forward_text_next_word('n', -1)<CR>
  inoremap <silent> <C-Right> <C-\><C-O>:call <SID>forward_text_next_word('i', -1)<CR>
  " Don't vmap C-Right, or after C-S-Right it'll keep selecting without
  " Shift pressed anymore, i.e., if we were to add this visual mode map:
  "   vnoremap <C-Right> e
endfunction

function! s:wire_keys_word_motions()
  call s:wire_keys_word_motions_leftward()
  call s:wire_keys_word_motions_rightward()
endfunction

function! s:inject_maps_word_motions()
  call <SID>free_keys_word_motions()
  call <SID>wire_keys_word_motions()
endfunction

" ========================================================================

call <SID>inject_maps_word_motions()


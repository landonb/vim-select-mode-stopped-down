" Improved wordy select-mode behavior wire to ctrl-select-left/-right work.
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Online: https://github.com/landonb/vim-select-mode-stopped-down
" License: https://creativecommons.org/publicdomain/zero/1.0/

" ========================================================================

" YOU: 1.) Uncomment the `let` to enable this feature; then
"      2.) Use <F9> to reload this script.
"      - HINT: <F9> defined by: landonb/dubs_ftype_mess or run:
"        noremap <silent><buffer> <F9> :exec 'source '.bufname('%')<CR>
"
"  let s:reloadable = 1
if exists("s:reloadable") && s:reloadable &&
    \ exists("g:loaded_vim_select_mode_stopped_down")
  unlet g:loaded_vim_select_mode_stopped_down
endif

" ***

if exists("g:loaded_vim_select_mode_stopped_down") || &cp
  finish
endif
let g:loaded_vim_select_mode_stopped_down = 1

" ========================================================================

function! s:trace_current_column_position(mode, dir)
  if trace#trace_level() <= 1 | return | endif

  let prefix = a:dir == 'fwd' ? 'fwd(1)' : 'rwd(-1)'
  echom l:prefix . ": a:mode: " . a:mode
  echom l:prefix . ": col(v): " . col("v") . " / virtcol(v): " . virtcol("v")
  echom l:prefix . ": col(.): " . col(".") . " / virtcol(.): " . virtcol(".")
  echom l:prefix . ": col($): " . col("$") . " / virtcol($): " . virtcol("$")
  echom l:prefix . ": getcurpos:  " . string(getcurpos())
  " echom l:prefix . ": v:count: " . v:count
endfunction

" ------------------------------------------------------------------------

function! s:trace_selection_bounds(calln)
  if trace#trace_level() <= 1 | return | endif

  let prefix = "selection/" . a:calln
  echom l:prefix . ":    virtcol(v):  " . string(virtcol("v"))
  echom l:prefix . ":    virtcol(.):  " . string(virtcol("."))
  echom l:prefix . ": beg/getpos(v):  " . string(getpos("v"))
  echom l:prefix . ": end/getpos(.):  " . string(getpos("."))
  echom l:prefix . ": lhs/getpos('<): " . string(getpos("'<"))
  echom l:prefix . ": rhs/getpos('>): " . string(getpos("'>"))
endfunction

" ========================================================================

" EXPLAINED: There's logic in select-leftward (extend_selection_by_word_reverse)
" that uses [:keyword:] in the @/ regex (\\k) to decide what to do when the
" cursor is at the the end of the line, or one position before it (penultimate).
"
" - I had issues when the cursor was on the last column and that
"   character was also a punctuation character, as explained here:
"
" - The word-ending check \\> does not work at second-to-last position,
"   e.g., suppose you have:
"
"           " foo. bar.
"                     ↑↑
"
"   and the cursor is at the last position, either over the period (in
"   normal mode), or to the right of the period (in insert mode). The
"   built-in `vb` command will jump the period and select the preceding
"   word, too, e.g.,:
"
"           " foo. bar.
"                  ----
"
"   where the dashes indicate what is selected.
"
"   This is different from non-line ending behavior, e.g., select-left
"   again and it selects up to the preceding word, e.g.,
"
"           " foo. bar.
"                ------
"
"   So you can see that the behavior at the end of the line should be
"   to just select the period, e.g.,:
"
"           " foo. bar.
"                     -
"
"   Indeed, with two dots, the left-select from end-of-line works-as-expected:
"
"           " foo. bar..
"                     --
"
" So in the following select-left function, we look for line-ending punctuation
" and handle it specially. We also use `gN`, not `vgN`, if the cursor is on the
" matching character, so that that's where the match starts, otherwise vgN
" jumps to previous match (including but not stopping on the one under the
" cursor, and a lone gN just jumps to the previous match to start the select
" and ignores any non-matching characters before then (so gN is only helpful
" if we know the cursor is on the match we're looking for).
"
" MAYBE/2020-02-24: There may be a more general case to solve here, i.e., instead
" of checking punctation, change @/ to something else that works well with `gN`.

" EXPLAINED: In the @/ regex pattern, we use two OR match groups,
" where each is of the form:
"     \\( ... \\| ... \\)
" so that one can use Vim's \zs to mark the start of the match:
"     \\(\\( ... \\)\\zs\\| ... \\)"
" - Because we do not want to include the matching character(s)
"   for any matches from the first group, which includes:
"     \\_^    match the start of the line; to add extra selection stop,
"               e.g., Vim's <b> command jumps from first word on one
"               line to beginning of last word of previous line, but
"               I'd like to add a stop of the beginning of the line, too;
"     \\<     match at the beginning of a "word" (a là iskeyword);
"     \\s\\+  match at beginning of visible characters, otherwise the motion
"             skips groups of one or more punctionation characters
"             surrounded by whitespace, e.g., a line in Vim like this:
"                 "   a comment!
"                 ?   ^ ^      ^
"             has motion stops at the 3 characters marked by ^,
"             but the opening double-quote comment character is skipped.
"             So a select-left sequence would look like this:
"                 "   a comment!
"                              -  !
"                       --------  comment!
"                     ----------  a comment!
"               ----------------    "   a comment!
"             but we'd like to have an additional stop on the lone quote, e.g.,
"                 "   a comment!
"                              -  !
"                       --------  comment!
"                     ----------  a comment!
"                 --------------  " a comment!
"               ----------------    "   a comment!

" ------------------------------------------------------------------------

" To handle the selection motion, we need to figure out where the cursor is.
" - For normal and insert modes, where there is no selection already started,
"   we could call col('.') to get the (byte-indexed) column, or we could call
"   getpos(".") or getcurpos() to also get the current line (see also: line(".")).
" - Note that getcurpos() is like getpos(".") but also returns curswant, which is
"   the same value as virtcol('.') in normal mode, if user didn't `$` to end of the
"   line (in which case curswant is -1/2147483647).
" - There are also two other similar calls, getpos("'<") and getpos("'>"), which
"   get the cursor positions at the beginning and end of the selection, respectively,
"   when in 'v'isual select mode.
"   - Also, one of getpos("'<") or getpos("'>") will match getpos(".")/getcurpos(),
"     depending on which direction the user built the selection -- and the other
"     getpos("'<") and getpos("'>") will match getpos("v").
"     - Caveat: But only after calling `gv` to restore the selection!
" - Note the getpos/getcurpos return 4 or five values:
"   - Index 0: "bufnum" is zero, or buffer number or the mark [so, zero];
"   - Index 1: "lnum" is the line number (>= 1) of the cursor in the buffer;
"   - Index 2: "col" is the byte-relevant (not character) cursor column (>= 1);
"   - Index 3: "off" is zero, unless "virtualedit" [ignored by us].
"   - Index 4: "curswant", reported by getcurpos(), is the 'preferred column
"              when moving vertically', i.e., the virtcol(".") of the cursor.
" - Note that getcurpos() reports three different values depending on context:
"   - If you alt-right to the end of the line, curswant is -1 (2147483647);
"     if you ctrl-right to the end of the line, curswant is same value as col;
"     if you right to the end of the line, curswant is one more than col.
"     ------------------------------------ | --------- | ----------
"     motion the moves cursor to $ of line | col value |  curswant
"     ------------------------------------ | --------- | ----------
"                      <M-Right> aka <End> |     n     | 2147483647
"                   <C-Right> aka e<Right> |     n     |      n
"                                  <Right> |     n     |    n + 1
"     ------------------------------------ | --------- | ----------
" - Also note that "col" counts bytes, whereas curswant counts characters,
"   so even when cursor is at the end of the line, if there are any Unicode
"   or multi-byte characters in the line, curswant < coln.
"   - More specifically, be sure to compare curswant against a virtcol()
"     value, and not against any byte column values, otherwise Unicode
"     in a line will break the logic.
"   - You'll also find that curswant is the same as virtcol(".")
"     when there's a selection.
" - Note that, when this function is first called in visual mode, the
"   getcol(".") and getcol("v") positions are the same, because the
"   selection is temporarily cleared, or something, to call the vnoremap
"   handler.
"   - But we can call `gv` to restore the selection, and then the two
"     values will represent the bounds of the selection: getcol("v")
"     indicates the starting position of the selection, and getcol(".")
"     represents the current cursor position (from which the selection
"     will be extended).
"   - Case in point, if we don't call `gv`, you'll see the following:
"     - Possibly because of the <C-U> (I'm guessing), or perhaps another
"       reason, unless `gv` is called to re-select the previous selection,
"       the getpos('.') and getpos('v') values will not represent the first
"       and final positions of the selection.
"     - E.g., if you Shift-Left to select backwards from column 13 back to 3
"       (where Shift-Left is handled by a builtin and not overridden by this
"       plugin), and then you Ctrl-Shift-Left (where Ctrl-Shift-Left *is*
"       handled by the plugin), you'd expect to see getpos('.') reflect
"       column 13, and getpos('v') to indicate column 3, but you'd be wrong,
"       e.g.,
"         rwd: getcurpos(): [0, 88, 3, 0, 3]
"              getpos("."): [0, 88, 3, 0]
"              getpos("v"): [0, 88, 3, 0]
"              getpos("'<"): [0, 88, 3, 0]
"              getpos("'>"): [0, 88, 13, 0]
"     - You'll notice that at least getpos("'<") and getpos("'>") are accurate,
"       at least for now -- they won't be updated until after the vnoremap call
"       completes, so once we start fiddling with the selection, '< and '> won't
"       be updated.
"     - Continuing the example, after our handler adjusts the selection,
"       e.g., after processing the Ctrl-Shift-Left from column 3 and
"       extending the selection, say, to the start of the line, then:
"         set_anchors: getcurpos(): [0, 250, 1, 0, 1]
"                      getpos("."): [0, 250, 1, 0]
"                      getpos("v"): [0, 250, 13, 0]
"                      getpos("'<"): [0, 250, 3, 0]
"                      getpos("'>"): [0, 250, 13, 0]
"     - If the motion was reversed, so the user used Shift-Right from column
"       3 to 13, then the first set of numbers would look the same as last time:
"         fwd: getcurpos(): [0, 88, 3, 0, 3]
"              getpos("."): [0, 88, 3, 0]
"              getpos("v"): [0, 88, 3, 0]
"              getpos("'<"): [0, 88, 3, 0]
"              getpos("'>"): [0, 88, 13, 0]
"     - But then, after adjusting the selection, the ending values would differ:
"         set_anchors: getcurpos(): [0, 3205, 16, 0, 16]
"                      getpos("."): [0, 3205, 16, 0]
"                      getpos("v"): [0, 3205, 3, 0]
"                      getpos("'<"): [0, 3205, 3, 0]
"                      getpos("'>"): [0, 3205, 13, 0]
function! s:prepare_selection_session(dirn, mode)
  call s:trace_current_column_position(a:mode, a:dirn == -1 ? 'rwd' : 'fwd')

  call s:trace_selection_bounds("1")

  if a:mode == 'v'
    " Already in 'v'isual select mode.
    " HACK: Make sure virtcol(v) and virtcol(.) are updated:
    "   Call `gv`, lest virtcol(v) == virtcol(.) == virtcol('<).
    silent! normal! gv
    call s:trace_selection_bounds("2")
  " else, a:mode =~ '[in]', and getpos(".") will be accurate.
  endif

  let [l:i_bufn, l:i_lnum, l:i_coln, l:i_voff, l:i_want] = range(0, 4)

  let end_pos = getpos(".")
  let ref_lnum = l:end_pos[l:i_lnum]
  let ref_coln = l:end_pos[l:i_coln]

  let virt_coln = virtcol(".")

  let ref_line = getline(l:ref_lnum)
  let line_nbytes = len(l:ref_line)
  let line_nchars = strchars(l:ref_line)

  if a:mode == 'i' && l:virt_coln == l:line_nchars
    " Edge case: in Insert mode, if cursor if in penultimate position,
    " or if it's at the final ($) position, the getpos(".")/virtcol(".")
    " positions are the same -- but curswant reveals the true position.
    let cur_pos = getcurpos()
    " Get the curswant value, i.e., getcurpos()[4].
    if l:cur_pos[l:i_want] > l:virt_coln
      let virt_coln += 1
    endif
  endif

  " Prepare for special case where Unicode is final character:
  " check character after end of selection and use its width to
  " calculate the byte column position of the following character,
  " to check if cursor at the penultimate line position.
  if l:ref_coln < len(l:ref_line)
    " ref_coln is 1-based, so this extracts substring starting at character after ref_coln.
    let snippet = strpart(l:ref_line, l:ref_coln)
    let next_bytes = strgetchar(l:snippet, 0)
    let next_char = nr2char(l:next_bytes)
    let nextchlen = len(l:next_char)
    if trace#trace_level() > 1
      call trace#trace("- next_coln:"
        \ . " snippet: " . l:snippet
        \ . " / next_bytes: " . l:next_bytes
        \ . " / next_char: " . l:next_char
        \ . " / nextchlen: " . l:nextchlen
      \)
    endif
  else
    let nextchlen = 0
  endif
  let next_coln = l:ref_coln + l:nextchlen

  " ***

  " FIXME/2020-05-13 16:19: We may not need prev_coln.
  " - I addd this block for parity with next_coln, but
  "   prev_coln so far unused (and probably won't be).

  if l:virt_coln > 1
    let prev_bytes = strgetchar(l:ref_line, l:virt_coln - 1)
    let prev_char = nr2char(l:prev_bytes)
    let prevchlen = len(l:prev_char)
    if trace#trace_level() > 1
      call trace#trace("- prev_coln:"
        \ . " prev_bytes: " . l:prev_bytes
        \ . " / prev_char: " . l:prev_char
        \ . " / prevchlen: " . l:prevchlen
      \)
    endif
  else
    let prevchlen = 0
  endif
  let prev_coln = l:ref_coln - l:prevchlen

  " ***

  let trace_vars = "dir(" . a:dirn . "):"
    \ . " ref_lnum: " . l:ref_lnum
    \ . " / ref_coln: " . l:ref_coln
    \ . " / line_nbytes: " . l:line_nbytes
    \ . " / line_nchars: " . l:line_nchars
    \ . " / virt_coln: " . l:virt_coln
    \ . " / next_coln: " . l:next_coln
    \ . " / prev_coln: " . l:prev_coln

  return [
    \ l:ref_lnum,
    \ l:ref_coln,
    \ l:line_nbytes,
    \ l:line_nchars,
    \ l:virt_coln,
    \ l:next_coln,
    \ l:prev_coln,
    \ l:trace_vars,
    \]
endfunction

" ========================================================================

function! s:extend_selection_by_word_reverse(mode)
  let last_pttrn = @/
  " Note that * does not need to be delimited, but \\+ does.
  let @/ = "\\(\\(\\_^\\|\\<\\|\\s\\+\\)\\zs\\|\\>\\)"

  let [
    \ ref_lnum,
    \ ref_coln,
    \ line_nbytes,
    \ line_nchars,
    \ virt_coln,
    \ next_coln,
    \ prev_coln,
    \ trace_vars
    \] = s:prepare_selection_session(-1, a:mode)

  " When selecting in reverse, treat newline as single word.
  " - But be aware if user selected forward first and then
  "   started selecting backwards, because vcol_curr represents
  "   the start of the *selection* and not where the cursor is
  "   (so the start of the selection is static after the cursor
  "   selects forward, until user selects reverse far enough to
  "   start extending selection before where they started).
  "
  if l:virt_coln == 1
    " Tortoise across line breaks.
    " MAYBE/2020-02-24: Make optional. Without setting this, selecting
    " leftward from first column will still select just the newline, unless
    " the line ends with [:punct:], then the punction and newline are added
    " to the selection.
    let @/ = "\\n"
    call trace#trace("RWD: first col: line break: " . l:trace_vars)
  endif

  " Note that mode() == 'v' does not work here because, e.g., inoremap
  " called Ctrl-O and entered normal mode before calling this function.
  if a:mode == 'v'
    " Start visual mode with same area as before (`gv`),
    " and select backward using MRU search pattern (`N`).
    " - Also manage wrapscan, to avoid selecting around file boundary.
    let was_wrapscan = &wrapscan
    set nowrapscan
    " We called `gv` in prepare_selection_session.
    " (Though calling again would not do any harm.)
      "      normal! gvN
    silent! normal! N
    if l:was_wrapscan | set wrapscan | endif
    call trace#trace("RWD: visual mode: " . l:trace_vars)
  else
    let nrmlc = ''
    " Check if on special-case column, such as first, second, or final column.
    if l:virt_coln == 1
      " Enter visual mode (`v`), and search r-ward using MRU search pattern (`gN`).
      " See also, set above: let @/ = "\\n", such that slow-walks across newlines.
      let nrmlc = 'vgN'
      call trace#trace("RWD: first col: insert mode: " . l:trace_vars)
    elseif l:virt_coln == 2 && l:line_nchars > 2
      " Because switched to normal mode, moving cursor left, to first column,
      " and then a `vgN` for some reason selects first two columns' characters,
      " rather than just first character/column.
      let nrmlc = 'hgN'
      call trace#trace("RWD: second col: " . l:trace_vars)
    " - Note: On an empty line, both return col(".") and col("$") return 1,
    "   so use >=, not ==; or use <. (Otherwise, col("$") is 1 more than length,
    "   and col(".") is at most length, but virt_coln == col("$") if you Ctrl-O
    "   from insert mode when cursor is at final position...
    " NOPE: elseif col(".") < col("$") - 1
    " SAME: elseif l:ref_coln < col("$") - 1
    " SORTS: elseif l:virt_coln < l:line_nchars
    " but really need to check mode, because virt_coln is line_nchars + 1 in
    " insert mode when cursor is past the final character.
    elseif 0
      \ || (a:mode == 'i' && l:virt_coln <= l:line_nchars)
      \ || (a:mode == 'n' && l:virt_coln < l:line_nchars)
      " Not on last column of the line, so may need to move cursor left one,
      " otherwise character under normal cursor (after character user expects
      " to be selected last) will get selected, too.
      let nrmlc = 'hvgN'
      call trace#trace("RWD: inside col: " . l:trace_vars)
    else
      " Edge-case: If last character in the iskeyword character class and the
      " character before it is not, or vice versa, need to not `vgN` but just `gN`,
      " otherwise selection jumps one additional word left. E.g., if the line ends:
      "     foo bar.
      "             ^
      " then ctrl-shift-left from cursor (^) should select just period '.', 'bar.'.
      " Note that we also check penultimate not whitespace, e.g.,
      "     foo bar .
      "              ^
      " because neither ' ' nor '.' match iskeyword (\k, or [:keyword:]),
      " but Vim considers whitespace boundaries when choosing words.
      let line_text = getline(l:ref_lnum)
      " Note that strlen() returns byte count, and strchars() returns char count,
      " i.e., to help handle multi-byte characters.
      let line_nchars = strchars(line_text)
      let char_penult = nr2char(strgetchar(line_text, line_nchars - 2))
      let char_ending = nr2char(strgetchar(line_text, line_nchars - 1))
      let isk_penult = l:char_penult =~ "\\k"
      let isk_ending = l:char_ending =~ "\\k"
      let iss_penult = l:char_penult =~ "\\s"
      let iss_ending = l:char_ending =~ "\\s"
      " Prepare a helpful trace message.
      let trace_isk = "char_penult: " . char_penult . " (" . l:isk_penult . ")"
        \ . " / char_ending: " . char_ending . " (" . l:isk_ending . ")"
      " Test if the last two characters are in separate classes.
      if a:mode == 'i' && l:virt_coln == l:line_nchars
        " A `gN` from the penultimate column in insert mode includes final character,
        " so move left first. (Note that virt_coln is line_nchars + 1 in $ position.
        execute "normal! h"
      endif
      " Handle whitespace specially because it's part of @/, and it lines ends
      " with whitespace, `gN` will grab newline, so use `vgN` or `hgN`.
      if !l:iss_ending
        \ && (l:iss_penult
        \   || (l:isk_penult && !l:isk_ending)
        \   || (!l:isk_penult && l:isk_ending))
        let nrmlc = 'gN'
        call trace#trace("RWD: final col/diff classes^: " . l:trace_isk . " / " . l:trace_vars)
      else
        let nrmlc = 'vgN'
        call trace#trace("RWD: final col/alike classes: " . l:trace_isk . " / " . l:trace_vars)
      endif
    endif

    execute "normal! " . l:nrmlc
  endif

  call s:ensure_select_mode()

  let @/ = l:last_pttrn
endfunction

" ========================================================================

function! s:extend_selection_by_word_forward(mode)
  let last_pttrn = @/
  " Sorta the opposite of the pattern in extend_selection_by_word_reverse.
  let @/ = "\\(\\_^\\zs\\|\\>\\|[\[:graph:]]\\zs[\[:blank:]]\\|\\n\\|[^\[:blank:]]\\<\\zs\\)"

  let [
    \ ref_lnum,
    \ ref_coln,
    \ line_nbytes,
    \ line_nchars,
    \ virt_coln,
    \ next_coln,
    \ prev_coln,
    \ trace_vars
    \] = s:prepare_selection_session(1, a:mode)

  " See also vcol_visi, the virtual column position of the first visible
  " character. This is the byte column of the first visible character.
  let ref_visi = s:get_leftmost_nonblank_byte_col(l:ref_lnum, l:ref_coln)

  if l:ref_coln < l:ref_visi
    " Select whitespace from cursor to before start of first word.
    let @/ = "\\_^[\[:blank:]]\\+\\zs"
  elseif l:ref_coln == l:ref_visi
    " Select words characters from cursor to end of first word,
    " |or to next space in case what's under character is solo
    " keyword character.
    " - Unless line is empty, in which case select newline until
    "   next start-of-word boundary, or space, or newline.
    if l:line_nchars > 0
      let @/ = "\\(\\>\\|[\[:space:]]\\)"
    else
      let @/ = "\\(\\<\\|[\[:space:]]\\|\\n\\)"
    endif
  endif

  let trace_prefix = ""
  if l:next_coln == l:line_nbytes
    " In insert mode before final line char; or normal mode atop final char.
    " In either case, select the final char.
    " Rather than select final column and newline, select just final column.
    if a:mode == 'v'
      " We called `gv` in prepare_selection_session.
      " (Though calling again would not do any harm.)
      "      normal! gv$
      normal! $
      let trace_prefix = "last col/+visual"
    else
      normal! vg$
      let trace_prefix = "last col/!visual"
    endif

  elseif l:ref_coln == l:line_nbytes
    if a:mode == 'v'
      let @/ = "\\_$\\zs"
      normal! gvn
      let trace_prefix = "final col/tortoise/visual"
    else
      let @/ = "\\_$\\zs"
      normal! gn
      let trace_prefix = "final col/tortoise/!visual"
    endif
  elseif a:mode == 'v'
    " Start visual mode with same area as before (`gv`),
    " and select forward using MRU search pattern (`n`).
    " - Unless on the final line, in which case `gvn` selects
    "   all the way back up to the top of the file...
    "   - But rather than check if on last line, e.g.,
    "       let was_on_last = line('.') == line('$')
    "     we can just set nowrapscan for the time being.
    let was_wrapscan = &wrapscan
    set nowrapscan
    " Strange: It's difficult to get rid of the nowrapscan message:
    "   E385: search hit BOTTOM without match for: \(\>\|[[:space:]]\)
    " - When I tried silent, e.g.,
    "     silent! normal! gvn
    "     silent! execute "normal! gvn"
    "   I see an ugly error message:
    "     Error detected while processing function
    "       <SNR>100_extend_selection_by_word_forward[12]
    "       ..<SNR>100_extend_selection_by_word_forward_select:
    "       line   38:
    "       E385: search hit BOTTOM without match for: \(\>\|[[:space:]]\)
    " - So don't use silent. And shouldn't matter execute or not, e.g.,
    "     normal! gvn
    "     execute "normal! gvn"
    " - Nonetheless, this still generates a message:
    "     /\(\>\|[[:space:]]\)
    try
      " We called `gv` in prepare_selection_session.
      " (Though calling again would not do any harm.)
      "      normal! gvn
      normal! n
    " We could catch all errors:
    "   catch /.*/
    " but safer to be specific:
    catch /^Vim\%((\a\+)\)\=:E385/
      " pass
    endtry
    if l:was_wrapscan | set wrapscan | endif
    let trace_prefix = "not final/visual"
  else
    if l:next_coln == l:line_nbytes
      " Tortoise across line breaks.
      let @/ = "\\_$\\zs"
      normal! gn
      let trace_prefix = "not final/!visual/tortoise"
    else
      let nrmlc = 'vn'
      " Use silent so message doesn't show @/ while user adjusts selection.
      execute "silent! normal! " . l:nrmlc
      let trace_prefix = "not final/!visual/!tortoise"
    endif
  endif

  call s:ensure_select_mode()

  call trace#trace("FWD: " . l:trace_prefix
    \ . ": ref_visi: " . l:ref_visi
    \ . " / " . l:trace_vars
    \)

  let @/ = l:last_pttrn

  " 2021-02-01: Not sure why, nor not sure why `silent!` prefixes are
  " not doing the trick, but it seems (by way of process of narrowing
  " it down using `echom` tracing) that `let @/ =` (and `silent! let`)
  " is echoing to the command window. Which we kludgely hide thusly:
  echo ""
endfunction

" ***

function! s:get_leftmost_nonblank_byte_col(ref_lnum, ref_coln)
  " Remember the current byte position.
  let l:waspos = getpos(".")
  " Jump to the assessed location.
  call setpos('.', [0, a:ref_lnum, a:ref_coln, 0])
  " Identify the leftmost column with a non-blank character.
  " - You can use ^ or _ to go to first character in line, but note that the
  "   dubs_buffer_fun plugin maps `__`, so if we used a single `_`, the
  "   command would be delayed.
  normal! ^
  let ref_visi = col(".")
  "  call trace#trace("ref_visi: " . l:ref_visi)
  " Return to original position.
  call setpos('.', l:waspos)
  return l:ref_visi
endfunction

" ***

function! s:ensure_select_mode()
  if mode() != 'v' | return | endif

  " Use v_CTRL-G to toggle between Visual mode and Select mode (to set
  " Select mode), so that, e.g., if user selects text, say, using
  " C-S-Right, that when they type next, the text is replaced, rather
  " than the selection being manipulated.
  execute "normal! \<C-G>"
endfunction

" ========================================================================

function! s:free_keys_extend_selection_by_word_reverse()
  silent! nunmap <C-S-Left>
  silent! iunmap <C-S-Left>
  silent! vunmap <C-S-Left>
endfunction

function! s:free_keys_extend_selection_by_word_forward()
  silent! nunmap <C-S-Right>
  silent! iunmap <C-S-Right>
  silent! vunmap <C-S-Right>
endfunction

function! s:free_keys_extend_selection_by_word()
  call <SID>free_keys_extend_selection_by_word_reverse()
  call <SID>free_keys_extend_selection_by_word_forward()
endfunction

function! s:wire_keys_extend_selection_by_word_reverse()
  nnoremap <silent> <C-S-Left> :<C-U>call <SID>extend_selection_by_word_reverse('n')<CR>
  inoremap <silent> <C-S-Left> <C-O>:<C-U>call <SID>extend_selection_by_word_reverse('i')<CR>
  vnoremap <silent> <C-S-Left> :<C-U>call <SID>extend_selection_by_word_reverse('v')<CR>
endfunction

function! s:wire_keys_extend_selection_by_word_forward()
  nnoremap <silent> <C-S-Right> :<C-U>call <SID>extend_selection_by_word_forward('n')<CR>
  inoremap <silent> <C-S-Right> <C-O>:<C-U>call <SID>extend_selection_by_word_forward('i')<CR>
  vnoremap <silent> <C-S-Right> :<C-U>call <SID>extend_selection_by_word_forward('v')<CR>
endfunction

function! s:wire_keys_extend_selection_by_word()
  call <SID>wire_keys_extend_selection_by_word_reverse()
  call <SID>wire_keys_extend_selection_by_word_forward()
endfunction

function! s:inject_maps_extend_selection_by_word()
  call <SID>free_keys_extend_selection_by_word()
  call <SID>wire_keys_extend_selection_by_word()
endfunction

" ========================================================================

if !exists("g:vim_select_mode_stopped_down_no_mappings")
    \ || !g:vim_select_mode_stopped_down_no_mappings
  call <SID>inject_maps_extend_selection_by_word()
endif


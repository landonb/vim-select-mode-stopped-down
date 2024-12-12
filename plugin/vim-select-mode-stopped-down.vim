" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/vim-select-mode-stopped-down#🛑
" License: https://creativecommons.org/publicdomain/zero/1.0/

" -------------------------------------------------------------------

" USAGE: After editing this plugin, you can reload it on the fly with
"        https://github.com/landonb/vim-source-reloader#↩️
" - Uncomment this `unlet` (or disable the `finish`) and hit <F9>.
"
" silent! unlet g:loaded_vim_select_mode_stopped_down_plugin

if exists("g:loaded_vim_select_mode_stopped_down_plugin") || &cp

  finish
endif

let g:loaded_vim_select_mode_stopped_down_plugin = 1

" -------------------------------------------------------------------

" USAGE: Set global variable to disable this plugin:
"
"   let g:vim_select_mode_stopped_down_no_mappings = 1

function! s:vim_select_mode_stopped_down_create_maps() abort
  if exists("g:vim_select_mode_stopped_down_no_mappings")
      \ && g:vim_select_mode_stopped_down_no_mappings

    return
  endif

  call g:embrace#alt_word_motion#inject_maps_word_motions()
  call g:embrace#alt_select_motion#inject_maps_extend_selection_by_word()
endfunction

call s:vim_select_mode_stopped_down_create_maps()


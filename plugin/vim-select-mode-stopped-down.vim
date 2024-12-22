" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/vim-select-mode-stopped-down#🛑
" License: https://creativecommons.org/publicdomain/zero/1.0/

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand("%:p") ==# expand("<sfile>:p")
  unlet g:loaded_vim_select_mode_stopped_down_plugin
endif

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


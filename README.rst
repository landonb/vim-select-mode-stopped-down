############################
vim-select-mode-stopped-down
############################

Tweaked ``select-mode`` Ctrl-Shift-Left and Ctrl-Shift-Right motions,
for ``behave mswin``.

About This Plugin
=================

If you like to select text with shift-arrow motions,
rather than using Vim's (admittedly more powerful)
Visual mode commands, this plugin might be for you!

When you call ``behave mswin``, Vim maps the Ctrl-Shift-Left
and Ctrl-Shift-Right keys to selecting text by the word-full.

But the default ``select-mode`` behavior |em_dash| at least in
my opinion |em_dash| is not quite perfect. I find it works well
in some situations, but for some uses, I usually need to modify
my adjustments with single-character Shift-left or Shift-right keys.

This plugin tweaks the Ctrl-Shift-Left and Ctrl-Shift-Right behavior
to make smaller selections, stopping at more column positions than
the default builtin functionality.

Install
=======

Installation is easy using the packages feature (see ``:help packages``).

To install the package so that it will automatically load on Vim startup,
use a ``start`` directory, e.g.,

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/start
    cd ~/.vim/pack/landonb/start

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/opt
    cd ~/.vim/pack/landonb/opt

Clone the project to the desired path:

.. code-block:: bash

    git clone https://github.com/landonb/vim-select-mode-stopped-down.git

If you installed to the optional path, tell Vim to load the package:

.. code-block:: vim

   :packadd! vim-select-mode-stopped-down

Just once, tell Vim to build the online help:

.. code-block:: vim

   :Helptags

Then whenever you want to reference the help from Vim, run:

.. code-block:: vim

   :help vim-select-mode-stopped-down

Overview
========

This plugin overrides how ``<Ctrl-Shift-Left>`` and ``<Ctrl-Shift-Right>`` behave.

The following changes are applied to the default behavior:

- The selection will stop before and after a line break,
  whether selecting forward or selecting reverse.

- The selection will stop between line-starting whitespace and
  the first word on the line.

- The selection will stop between the penultimate column and the
  final column of the line if the second-to-last character is a
  keyword character, and the final character is punctuation.
  (Otherwise, e.g., selecting left on a line that reads like
  ``this text. And this.`` from the final column would first
  select ``this.``, then ``And this.``, then ``. And this.``, which
  just doesn't feel right. So adds initial selection of just ``.``.

- The selection handles exclusive/inclusive motions as appropriate.
  E.g., by default, select is exclusive, so if the cursor is on the
  final column of a line, selecting leftward excludes the final
  character. But this plugin will assume that if you're selecting
  leftward from the rightmost column, that you probably also want
  to include the rightmost character.

Configuration
=============

This plugin binds the ``<Ctrl-Shift-Left>`` and ``<Ctrl-Shift-Right>``
key mappings by default.

To provide your own bindings, set the no-mappings global,
and then map the key bindings from your own code, e.g.,::

  let g:vim_select_mode_stopped_down_no_mappings = 1

  nnoremap <silent> <C-S-Left> :<C-U>call <SID>extend_selection_by_word_reverse('n')<CR>
  inoremap <silent> <C-S-Left> <C-O>:<C-U>call <SID>extend_selection_by_word_reverse('i')<CR>
  vnoremap <silent> <C-S-Left> :<C-U>call <SID>extend_selection_by_word_reverse('v')<CR>

  nnoremap <silent> <C-S-Right> :<C-U>call <SID>extend_selection_by_word_forward('n')<CR>
  inoremap <silent> <C-S-Right> <C-O>:<C-U>call <SID>extend_selection_by_word_forward('i')<CR>
  vnoremap <silent> <C-S-Right> :<C-U>call <SID>extend_selection_by_word_forward('v')<CR>


set viminfofile=@viminfoFile@

" += rather than =, so the rest of vim's default shortmess is kept.
set shortmess+=I

" Packages under pack/*/start reach runtimepath only after the vimrc has
" run, so a colorscheme command here would not find them.
packloadall!

" fzf inside vim takes its colours from the colourscheme rather than
" from $FZF_DEFAULT_OPTS, so it follows the appearance switch below.
" Each entry is [attribute, highlight-group...] and the first group that
" exists wins.
let g:fzf_colors = {
  \ 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

@appearance@

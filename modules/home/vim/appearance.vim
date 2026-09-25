" Dracula Pro / Alucard for Vim, following the macOS appearance.
"
" The colourschemes themselves are upstream, in dracula-pro/themes/vim:
" `dracula-pro` is the dark one and `dracula-pro-alucard` the light
" one. This file is only the glue that picks between them, which
" upstream does not do.

" Sourced files inherit the caller's 'cpoptions', and a 'compatible'
" vim has line continuation and <> notation switched off -- which
" fails at parse time with a misleading E10, not where the mistake
" looks like it is. Every vim runtime file opens this way for that
" reason.
let s:save_cpo = &cpoptions
set cpoptions&vim

" How often to re-check the appearance. A check is cheap enough to be
" frequent.
let s:INTERVAL = 2000

function! s:Ask() abort
  " macOS leaves AppleInterfaceStyle unset in Light Mode, so the exit
  " status is the signal rather than the output.
  call system('defaults read -g AppleInterfaceStyle')
  return v:shell_error == 0 ? 'dark' : 'light'
endfunction

function! s:ForceBackground(bg) abort
  " Every Dracula Pro scheme sources dracula-pro-base.vim, which ends
  " with an unconditional `set background=dark` -- wrong for Alucard,
  " and it tells other plugins the ground is dark when it is not.
  " Setting it back cannot be done plainly: 'background' reloads the
  " colour scheme whenever g:colors_name exists, and that reload clears
  " every highlight group. Hiding colors_name for the one statement
  " skips the reload; the groups already set stay set, since
  " 'background' only rebuilds the defaults.
  if &background ==# a:bg
    return
  endif
  let l:name = get(g:, 'colors_name', '')
  unlet! g:colors_name
  let &background = a:bg
  if !empty(l:name)
    let g:colors_name = l:name
  endif
endfunction

" Groups that would otherwise fill the window with an opaque colour.
" The terminal is already painting a background -- with opacity and
" blur, in Ghostty's case -- and a colour scheme covering every cell
" throws that away. Anything that needs to read as a distinct surface
" (statusline, the visual selection, search matches, the cursor line's
" own highlight) deliberately keeps its background.
let s:TRANSPARENT_GROUPS = [
      \ 'Normal',
      \ 'NonText',
      \ 'EndOfBuffer',
      \ 'LineNr',
      \ 'SignColumn',
      \ 'FoldColumn',
      \ ]

function! s:ClearBackgrounds() abort
  if !get(g:, 'dracula_pro_transparent', 1)
    return
  endif
  for l:group in s:TRANSPARENT_GROUPS
    if hlexists(l:group)
      " Naming only the background leaves every other attribute alone
      " -- :highlight is additive unless told to clear.
      execute 'highlight' l:group 'ctermbg=NONE guibg=NONE'
    endif
  endfor
endfunction

function! s:Set(want) abort
  let g:dracula_pro_variant = a:want
  if a:want ==# 'light'
    colorscheme dracula-pro-alucard
  else
    colorscheme dracula-pro
  endif
  call s:ForceBackground(a:want)
  " Last, because both :colorscheme and a 'background' change rebuild
  " the default groups and would undo this.
  call s:ClearBackgrounds()
endfunction

function! DraculaProApply(ask) abort
  " a:ask -- 0 trusts $APPEARANCE if it is set, 1 always asks macOS.
  " Startup trusts it; anything later cannot, because a process's
  " environment does not change while it runs.
  if !a:ask && !empty($APPEARANCE)
    let l:want = $APPEARANCE
  else
    let l:want = s:Ask()
  endif
  " Reapply when the variant differs, and also when the colour scheme
  " has gone missing underneath us -- see s:Poll for how that happens.
  if l:want ==# get(g:, 'dracula_pro_variant', '') && exists('g:colors_name')
    return
  endif
  call s:Set(l:want)
endfunction

function! s:Poll(...) abort
  " Vim runs its own terminal-background detection and will set
  " 'background' when the terminal restyles -- and doing so *clears the
  " colour scheme*, g:colors_name and every highlight group with it.
  " That cannot be hooked (OptionSet fires only for our own writes, not
  " for that one) and it cannot be relied on either: it is driven by an
  " unsolicited OSC 11 report from the terminal, which Ghostty sends on
  " some launches and not others. So treat it purely as damage to
  " repair, and repair it from 'background' rather than waiting for the
  " check below, since that is both instant and free.
  if exists('g:dracula_pro_variant') && !exists('g:colors_name')
    call s:Set(&background)
  endif

  " The authoritative check. Polling is the only option left: vim 9.1
  " does not understand the terminal's in-band push notification (DEC
  " mode 2031, which Ghostty does emit -- `CSI ? 997 ; 1 n` dark,
  " `; 2 n` light), and teaching it that sequence means binding it as
  " a raw key, which drops stray bytes into a buffer in any mode the
  " mapping misses. Not worth that for a colour scheme.
  call DraculaProApply(1)
endfunction

" The palettes are 24-bit; without this vim quantises them to 256
" colours.
if has('termguicolors')
  set termguicolors
endif

call DraculaProApply(0)

" FocusGained catches coming back to the terminal after switching
" appearance elsewhere. It needs 'nocompatible': vim does not enable
" focus reporting in compatible mode, and `vim -u <file>` leaves
" compatible on -- so a test invoked that way shows no focus events
" while real use works fine.
augroup DraculaProAppearance
  autocmd!
  autocmd FocusGained * call DraculaProApply(1)
augroup END

" ...and the poll, for the appearance flipping while vim itself is
" focused, which is what the automatic sunset switch does.
if has('timers') && !exists('s:timer')
  let s:timer = timer_start(s:INTERVAL, function('s:Poll'), {'repeat': -1})
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo

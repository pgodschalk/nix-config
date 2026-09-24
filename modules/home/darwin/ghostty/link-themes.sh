# shellcheck shell=bash

# Spliced in once per directory in `themeDirs`. Symlinks rather than
# copies, so an edit in the checkout applies without a switch, and a
# missing checkout warns rather than aborting activation.
if [ -d @themes@ ]; then
  run mkdir -p @dir@

  for ghosttyTheme in alucard pro; do
    run ln -sfn @themes@/"$ghosttyTheme" @dir@/"$ghosttyTheme"
  done
else
  printf >&2 'warning: %s is missing; Ghostty themes not linked\n' @themes@
fi

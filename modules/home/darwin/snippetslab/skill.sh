# shellcheck shell=bash

# Generated rather than linked, because the text lives inside the app
# and changes with it. Copied rather than symlinked, since every
# destination is outside the store.
lab=@lab@

if [ -x "$lab" ]; then
  destinations=(@destinations@)
  for dest in "${destinations[@]}"; do
    run mkdir -p "$dest/snippetslab"
  done

  # Guarded rather than wrapped in `run`, which under a dry run would
  # echo the command into the redirect's target.
  if [[ ! -v DRY_RUN ]]; then
    first=${destinations[0]}/snippetslab/SKILL.md
    if "$lab" skill show >"$first.tmp"; then
      mv -f "$first.tmp" "$first"
      for dest in "${destinations[@]:1}"; do
        cp -f "$first" "$dest/snippetslab/SKILL.md"
      done
    else
      rm -f "$first.tmp"
    fi
  fi
else
  echo "snippetslab: SnippetsLab not installed; skipping its agent skill" >&2
fi

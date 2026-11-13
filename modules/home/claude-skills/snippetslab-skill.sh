# shellcheck shell=bash

# Generated rather than linked, because the text lives inside the app
# and changes with it. Copied rather than symlinked, since every
# destination is outside the store.
lab=/Applications/SnippetsLab.app/Contents/Helpers/lab

if [ -x "$lab" ]; then
  skillFiles=(@skillFiles@)
  for skill in "${skillFiles[@]}"; do
    run mkdir -p "$(dirname "$skill")"
  done

  # Guarded rather than wrapped in `run`, which under a dry run would
  # echo the command into the redirect's target.
  if [[ ! -v DRY_RUN ]]; then
    first=${skillFiles[0]}
    if "$lab" skill show >"$first.tmp"; then
      mv -f "$first.tmp" "$first"
      for skill in "${skillFiles[@]:1}"; do
        cp -f "$first" "$skill"
      done
    else
      rm -f "$first.tmp"
    fi
  fi
else
  echo "claude-skills: SnippetsLab not installed; skipping its agent skill" >&2
fi

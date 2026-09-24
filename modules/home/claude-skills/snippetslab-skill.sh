# shellcheck shell=bash

# Generated rather than linked, because the text lives inside the app
# and changes with it. Copied rather than symlinked, since the
# destination is outside the store.
lab=/Applications/SnippetsLab.app/Contents/Helpers/lab

if [ -x "$lab" ]; then
  agentSkill=@agentSkill@
  claudeSkill=@claudeSkill@
  run mkdir -p "$(dirname "$agentSkill")" "$(dirname "$claudeSkill")"

  # Guarded rather than wrapped in `run`, which under a dry run would
  # echo the command into the redirect's target.
  if [[ ! -v DRY_RUN ]]; then
    if "$lab" skill show >"$agentSkill.tmp"; then
      mv -f "$agentSkill.tmp" "$agentSkill"
      cp -f "$agentSkill" "$claudeSkill"
    else
      rm -f "$agentSkill.tmp"
    fi
  fi
else
  echo "claude-skills: SnippetsLab not installed; skipping its agent skill" >&2
fi

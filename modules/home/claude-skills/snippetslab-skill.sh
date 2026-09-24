# shellcheck shell=bash

# Generated rather than linked, because the text lives inside the app
# and changes with it. Copied rather than symlinked, since the
# destination is outside the store.
lab=/Applications/SnippetsLab.app/Contents/Helpers/lab

if [ -x "$lab" ]; then
  agentSkill=@agentSkill@
  claudeSkill=@claudeSkill@
  run mkdir -p "$(dirname "$agentSkill")" "$(dirname "$claudeSkill")"

  if run "$lab" skill show >"$agentSkill"; then
    run cp -f "$agentSkill" "$claudeSkill"
  fi
else
  echo "claude-skills: SnippetsLab not installed; skipping its agent skill" >&2
fi

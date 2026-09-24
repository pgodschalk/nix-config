# shellcheck shell=bash

vcs="$1"

# Read into a variable rather than substituted into the `[ ]` tests
# below, where a placeholder is a string to the checker and draws SC2170
# on a template that is fine once substituted.
#
# No comment line here may begin with the checker's own name, or it is
# read as a directive and the file fails to parse.
subject_limit=@subjectLimit@

# $2 is the profile. The whole `case` is substituted as one piece:
# generated branches spliced inside one leave a template that is not
# parseable shell, so the checker gives up on the file rather than
# checking any of it.
@contextCase@

key="$(@fnox@ get --profile lumen LUMEN_API_KEY 2>/dev/null)" || key=""

if [ -z "$key" ]; then
  echo "commit message: could not resolve the lumen API key; skipping" >&2
  exit 1
fi

draft_once() {
  LUMEN_API_KEY="$key" @lumen@ \
    --config @lumenConfig@ --vcs "$vcs" draft --context "$1" 2>/dev/null
}

# context is assigned by the fragment above, which is an opaque
# placeholder to the checker. Written without its `@`, since replaceVars
# substitutes inside comments too.
# shellcheck disable=SC2154
draft="$(draft_once "$context")" || draft=""

if [ -z "$draft" ]; then
  echo "commit message: lumen produced nothing; skipping" >&2
  exit 1
fi

# A language model cannot count characters reliably.
subject="$(printf '%s\n' "$draft" | head -1)"

if [ "${#subject}" -gt "$subject_limit" ]; then
  retry="$context The subject you produced was ${#subject} characters, \
which is too long. Count the characters: the subject MUST be \
$subject_limit or fewer. Shorten it."
  draft2="$(draft_once "$retry")" || draft2=""

  if [ -n "$draft2" ]; then
    subject2="$(printf '%s\n' "$draft2" | head -1)"

    # Take the retry when it is within budget or merely shorter: the
    # message lands in the editor either way, so a closer miss beats the
    # first attempt.
    if [ "${#subject2}" -le "$subject_limit" ] \
      || [ "${#subject2}" -lt "${#subject}" ]; then
      draft="$draft2"
    fi
  fi
fi

printf '%s\n' "$draft"

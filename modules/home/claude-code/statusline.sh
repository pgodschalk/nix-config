#!/usr/bin/env bash
#
# Claude Code's status line, reading its session JSON on stdin.
#
#   ✻ Opus 5 · default │ nix-config/modules/home │  master*
#   ▓▓▓░░░░░░░ 72% left │ $0.42
#
# Colours are ANSI palette slots rather than literal hex, so the
# terminal swaps them with the macOS appearance and this needs no
# detection of its own. Two mappings read as wrong and are not: Dracula
# Pro puts pink at slot 5 and purple at slot 4. Slot 8 is unused because
# Alucard maps it to #FFFFFF, invisible against its background.
#
# This runs in whatever environment Claude Code hands it, with no
# guarantee about PATH, so both external tools are resolved with an
# absolute fallback and an unreachable one costs its segment rather than
# the line.
#
# `set -e` is deliberately absent: `read` returns non-zero on a final
# field with no trailing newline while having read it perfectly well.

set -u

input=$(cat)

jq_bin=$(command -v jq 2>/dev/null || true)
if [ -z "$jq_bin" ] && [ -x /usr/bin/jq ]; then jq_bin=/usr/bin/jq; fi
[ -n "$jq_bin" ] || exit 0

git_bin=$(command -v git 2>/dev/null || true)
if [ -z "$git_bin" ] && [ -x /usr/bin/git ]; then git_bin=/usr/bin/git; fi

# One jq invocation for every field, since the status line re-runs on
# each assistant message.
#
# Two things here are load-bearing. Every field uses `// ""` and never
# `// empty`, which would drop the element rather than emit a blank one
# and shift every later field up. And the fields are newline-separated
# and read one at a time rather than tab-separated into a single `read`:
# tab is one of IFS's whitespace characters, so bash collapses runs of
# them and one empty field silently shifts every later column, rendering
# plausibly with the wrong values.
#
# Any newline or tab inside a value is flattened to a space, so one
# value cannot become two lines.
fields=$("$jq_bin" -r --from-file @filter@ <<<"$input" 2>/dev/null) || exit 0
[ -n "$fields" ] || exit 0

MODEL="?"
CUR_DIR=""
PROJ_DIR=""
STYLE=""
USED=""
REMAIN=""
COST=0

# `IFS=` keeps each line exactly as jq emitted it; the default would
# strip whitespace from a path. One line per field rather than
# `mapfile`, which is bash 4+ and so unavailable if this ever resolves
# to Apple's /bin/bash.
{
  IFS= read -r MODEL || true
  IFS= read -r CUR_DIR || true
  IFS= read -r PROJ_DIR || true
  IFS= read -r STYLE || true
  IFS= read -r USED || true
  IFS= read -r REMAIN || true
  IFS= read -r COST || true
} <<<"$fields"

e=$(printf '\033')
R="${e}[0m"
BOLD="${e}[1m"
RED="${e}[31m"
GREEN="${e}[32m"
YELLOW="${e}[33m"
PURPLE="${e}[34m"
PINK="${e}[35m"
CYAN="${e}[36m"

SEP="${PURPLE}│${R}"

# The directory relative to the project root, prefixed by the project's
# own name, which keeps where-in-the-project you are without the prefix
# every repository here shares.
location=""

if [ -n "$CUR_DIR" ]; then
  if [ -n "$PROJ_DIR" ] && [ "$CUR_DIR" = "$PROJ_DIR" ]; then
    location="${PROJ_DIR##*/}"
  elif [ -n "$PROJ_DIR" ] && [ "${CUR_DIR#"$PROJ_DIR"/}" != "$CUR_DIR" ]; then
    location="${PROJ_DIR##*/}/${CUR_DIR#"$PROJ_DIR"/}"
  else
    # A `case` rather than ${var/#$HOME/~}, which treats $HOME as a glob
    # pattern, so a home directory containing a bracket would match
    # something other than itself.
    #
    # The `~` here is display text rather than a path being resolved, so
    # SC2088 is a false positive -- and it must stay suppressed or
    # writeShellApplication fails the build.
    # shellcheck disable=SC2088
    case "$CUR_DIR" in
      "$HOME") location="~" ;;
      "$HOME"/*) location="~/${CUR_DIR#"$HOME"/}" ;;
      *) location="$CUR_DIR" ;;
    esac
  fi
fi

# `--porcelain=v2 --branch` answers both questions in one invocation:
# the branch from the `# branch.head` header, and whether anything is
# modified from the presence of any non-header line.
#
# This is the expensive part of the script, almost all of it the
# untracked-file scan. `-uno` would halve it and is deliberately not
# used: it reports a repository holding nothing but new files as clean,
# which is when the marker matters most. Claude Code debounces at 300ms
# and cancels an in-flight script.
branch=""
dirty=""

if [ -n "$git_bin" ] && [ -n "$CUR_DIR" ] && [ -d "$CUR_DIR" ]; then
  # --no-optional-locks: a plain status takes index.lock to refresh the
  # index, racing the agent's own git commands.
  status=$("$git_bin" --no-optional-locks -C "$CUR_DIR" status \
    --porcelain=v2 --branch 2>/dev/null || true)

  if [ -n "$status" ]; then
    while IFS= read -r line; do
      case "$line" in
        "# branch.head "*) branch="${line#\# branch.head }" ;;
        # Any other header -- oid, upstream, ab -- is of no interest.
        \#*) ;;
        # Porcelain v2 entries begin 1, 2, u or ?, never #, so anything
        # that is not a header is a change of some kind.
        *) dirty="*" ;;
      esac
    done <<<"$status"

    [ "$branch" = "(detached)" ] && branch="detached"
  fi
fi

# Model and output style are adjacent because they answer the same
# question.
line1="${CYAN}✻ ${MODEL}${R}"
[ -n "$STYLE" ] && line1+="${PURPLE} · ${R}${YELLOW}${STYLE}${R}"
[ -n "$location" ] && line1+=" ${SEP} ${BOLD}${location}${R}"
# U+E725 (nf-dev-git_branch), which needs the Nerd Font build both
# emulators use.
[ -n "$branch" ] && line1+=" ${SEP} ${PINK} ${branch}${R}${YELLOW}${dirty}${R}"

WIDTH=10
if [ -n "$USED" ] && [ -n "$REMAIN" ]; then
  used_int=${USED%%.*}
  remain_int=${REMAIN%%.*}
  [ -n "$used_int" ] || used_int=0
  [ -n "$remain_int" ] || remain_int=0

  # Rounded rather than truncated, so 1% does not read as 0 and 99% does
  # not read as full.
  filled=$(((used_int * WIDTH + 50) / 100))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$WIDTH" ] && filled=$WIDTH

  # Coloured on what is left, which is the number reported.
  if [ "$remain_int" -ge 50 ]; then
    ctx=$GREEN
  elif [ "$remain_int" -ge 20 ]; then
    ctx=$YELLOW
  else
    ctx=$RED
  fi

  bar=""
  i=0

  while [ "$i" -lt "$WIDTH" ]; do
    if [ "$i" -lt "$filled" ]; then bar+="▓"; else bar+="░"; fi
    i=$((i + 1))
  done

  line2="${ctx}${bar} ${remain_int}% left${R}"
else
  # Null until the first API response of a session, and again after
  # /compact.
  line2="${PURPLE}░░░░░░░░░░ —% left${R}"
fi

cost_fmt=$(printf '%.2f' "${COST:-0}" 2>/dev/null || printf '0.00')
line2+=" ${SEP} ${GREEN}\$${cost_fmt}${R}"

printf '%s\n%s\n' "$line1" "$line2"

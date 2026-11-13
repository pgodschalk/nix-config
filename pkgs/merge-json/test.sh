#!/usr/bin/env bash

# Usage: test.sh MERGE_JSON [CASES]
#
# Runs MERGE_JSON once per case directory under CASES, tests/ beside
# this script by default. A case holds:
#
#   file.json            the app's file before the merge; file.txt
#                        instead for content that is not valid JSON,
#                        neither for a file that does not exist yet
#   old.json             the state the last run left, if there was one
#   old-strategies.json  the strategies the last run left, if any
#   new.json             what is declared now
#   strategies.json      the strategies, in new.json's shape, if any
#   expected.json        the app's file after the merge
#
# A case with expected.json also expects the state to be new.json and
# the strategies' state to be strategies.json, or {} without one.
# A case without expected.json expects the entry to be skipped: exit 0,
# a warning naming the entry, and the file and both states byte for
# byte as they were.
set -euo pipefail

merge_json=$1
cases=${2:-$(dirname "$0")/tests}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

empty="$work/empty.json"
echo '{}' >"$empty"

failures=0

fail() {
  echo "FAIL $1: $2"
  failures=$((failures + 1))
}

# Compares two JSON files with their keys sorted, so only content
# counts.
same_json() {
  diff -u <(jq -S . "$1") <(jq -S . "$2")
}

# Compares two files that may not exist: both absent counts as equal.
same_bytes() {
  if [ -e "$1" ] || [ -e "$2" ]; then
    cmp "$1" "$2"
  fi
}

for fixture in "$cases"/*/; do
  fixture=${fixture%/}
  name=$(basename "$fixture")
  root="$work/$name"
  file="$root/app/settings.json"
  state="$root/state/$name.json"
  strategies_state="$root/state/$name.strategies.json"
  mkdir -p "$root"

  original=
  for candidate in "$fixture/file.json" "$fixture/file.txt"; do
    if [ -e "$candidate" ]; then
      original=$candidate
    fi
  done

  # Neither directory exists unless the case puts a file in it, so
  # merge-json has to create them.
  if [ -n "$original" ]; then
    mkdir -p "$root/app"
    cp "$original" "$file"
  fi
  if [ -e "$fixture/old.json" ]; then
    mkdir -p "$root/state"
    cp "$fixture/old.json" "$state"
  fi
  if [ -e "$fixture/old-strategies.json" ]; then
    mkdir -p "$root/state"
    cp "$fixture/old-strategies.json" "$strategies_state"
  fi

  args=("$name" "$file" "$fixture/new.json" "$state")
  expected_strategies=$empty
  if [ -e "$fixture/strategies.json" ]; then
    args+=("$fixture/strategies.json")
    expected_strategies=$fixture/strategies.json
  fi

  if ! "$merge_json" "${args[@]}" 2>"$root/stderr"; then
    fail "$name" "exited non-zero"
    cat "$root/stderr"
    continue
  fi

  if [ -e "$fixture/expected.json" ]; then
    if ! same_json "$fixture/expected.json" "$file"; then
      fail "$name" "the file differs from expected.json"
      continue
    fi
    if ! same_json "$fixture/new.json" "$state"; then
      fail "$name" "the state differs from new.json"
      continue
    fi
    if ! same_json "$expected_strategies" "$strategies_state"; then
      fail "$name" "the strategies' state differs from the strategies"
      continue
    fi
  else
    if ! grep -q -- "^$name: " "$root/stderr"; then
      fail "$name" "no warning naming the entry"
      continue
    fi
    if ! same_bytes "$original" "$file"; then
      fail "$name" "the file was changed"
      continue
    fi
    if ! same_bytes "$fixture/old.json" "$state"; then
      fail "$name" "the state was changed"
      continue
    fi
    if ! same_bytes "$fixture/old-strategies.json" "$strategies_state"; then
      fail "$name" "the strategies' state was changed"
      continue
    fi
  fi

  echo "ok $name"
done

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi

# shellcheck shell=bash

# A subshell keeps the loop's variables out of the rest of the
# activation script.
(
  while IFS= read -r -d '' name \
    && IFS= read -r -d '' file \
    && IFS= read -r -d '' declared \
    && IFS= read -r -d '' state \
    && IFS= read -r -d '' strategies; do
    # merge-json skips a file it cannot merge and exits 0, so a failure
    # is unexpected; it still must not stop the activation.
    run @mergeJson@ "$name" "$file" "$declared" "$state" "$strategies" \
      || echo "$name: $file not merged" >&2
  done < <(@jq@ --raw-output0 --from-file @entries@ @manifest@)
)

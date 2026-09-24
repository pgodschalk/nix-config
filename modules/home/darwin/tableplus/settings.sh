# shellcheck shell=bash

# A running TablePlus may write its in-memory ViewSetting back over
# these.
if /usr/bin/pgrep -xq TablePlus; then
  echo "tableplus: TablePlus is running; it may overwrite these" >&2
  echo "tableplus: settings." >&2
fi

@viewSettings@

# The model is substituted in, so its version annotation sits beside the
# binding in the .nix rather than inside this command: a `\`
# continuation splices the next line on, and a comment there would
# swallow the rest of it.
run /usr/bin/defaults write @domain@ default_vendor -string anthropic_ai
run /usr/bin/defaults write @domain@ default_vendor_options \
  -dict-add anthropic_ai_default_model -string @model@

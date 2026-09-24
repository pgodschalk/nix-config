# shellcheck shell=bash

# Copied and chmod'd rather than declared with xdg.configFile: glab
# refuses a config that is not mode 0600, a store file is 0444, and
# home-manager has no option for a managed file's mode.
run @coreutils@/bin/mkdir -p @dir@
run @coreutils@/bin/cp -f @src@ @dst@
run @coreutils@/bin/chmod 600 @dst@

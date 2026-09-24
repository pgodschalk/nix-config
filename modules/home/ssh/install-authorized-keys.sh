# shellcheck shell=bash

# Copied rather than linked: with StrictModes, sshd follows the link and
# rejects the file because /nix/store is group-writable. `rm` first,
# since `cp` onto an old store link would write through it.
run @coreutils@/bin/mkdir -p @dir@
run @coreutils@/bin/chmod 700 @dir@
run @coreutils@/bin/rm -f @dst@
run @coreutils@/bin/cp @src@ @dst@
run @coreutils@/bin/chmod 600 @dst@

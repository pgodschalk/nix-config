# shellcheck shell=bash

# `developerSettings.lspBinaries` maps a language id to a single
# absolute path with nowhere to put arguments, so every server that
# needs any gets one of these in front of it.
exec @exe@ @args@ "$@"

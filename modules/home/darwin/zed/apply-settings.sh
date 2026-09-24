# shellcheck shell=bash

# A real writable file at ~/.config/zed, because Zed ignores
# XDG_CONFIG_HOME on macOS and the renderer splices in a token that
# must not reach the store.
run @render@ @base@ @target@

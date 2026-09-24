# shellcheck shell=bash

# Xcode's lldb-dap, which has the Swift language plugin, through
# xcrun so it follows the selected developer directory.
exec /usr/bin/xcrun lldb-dap "$@"

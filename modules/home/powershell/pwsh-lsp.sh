# shellcheck shell=bash
set -eu

# A fresh session directory per launch, because PSES writes session
# details on startup and two editors sharing one path overwrite each
# other's. Nothing cleans it up -- `exec` replaces this shell, so a trap
# would never fire -- and macOS's per-boot TMPDIR clears it.
session=$(mktemp -d "${TMPDIR:-/tmp}/pses.XXXXXX")

# `-LogLevel Warning` because the server warns that Normal is
# deprecated, and the warning arrives as a window/logMessage every
# session.
exec @pwsh@ -NoLogo -NoProfile -Command \
  "@bundled@/PowerShellEditorServices/Start-EditorServices.ps1 \
     -HostName Helix -HostProfileId helix -HostVersion 1.0.0 \
     -BundledModulesPath '@bundled@' \
     -LogPath '$session/pses.log' \
     -SessionDetailsPath '$session/session.json' \
     -LogLevel Warning -Stdio"

# Orca's own gh and glab come first only in a shell Orca started, which
# carries its bundle identifier; Orca takes its PATH from this shell.
if [[ ${__CFBundleIdentifier-} == com.stablyai.orca ]]; then
  path=(@bin@ $path)
fi

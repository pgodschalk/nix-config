# shellcheck shell=bash

# home-manager's own batCache entry exports XDG_CACHE_HOME but not
# XDG_CONFIG_HOME, and activation runs under `sudo -u` with env_reset.
# bat would look in ~/.config/bat, find no themes, and build a cache
# without them while reporting success.
(
  export XDG_CACHE_HOME=@cacheHome@
  export BAT_CONFIG_DIR=@configDir@
  verboseEcho "Rebuilding bat theme cache"
  cd "@emptyDir@" || exit
  run @bat@ cache --build
)

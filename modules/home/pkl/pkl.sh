# shellcheck shell=bash
# The pkl CLI keeps its package cache in ~/.pkl/cache whatever
# XDG_CACHE_HOME says, so every subcommand that takes --cache-dir gets
# one under the XDG cache. A later --cache-dir, such as the one pkl-lsp
# passes to download-package, wins.
cache="${XDG_CACHE_HOME:-@cacheHome@}/pkl"

case "${1-}" in
  eval | test | repl | download-package | run)
    subcommand=$1
    shift
    exec @pkl@ "${subcommand}" --cache-dir "${cache}" "$@"
    ;;
  project | analyze)
    case "${2-}" in
      resolve | package | imports)
        command=$1
        subcommand=$2
        shift 2
        exec @pkl@ "${command}" "${subcommand}" --cache-dir "${cache}" "$@"
        ;;
    esac
    ;;
esac

exec @pkl@ "$@"

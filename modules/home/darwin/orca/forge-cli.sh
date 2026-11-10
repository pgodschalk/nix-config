# shellcheck shell=bash

# Orca runs gh and glab by name, so the Nushell wrappers that fetch
# their tokens from 1Password never apply; a keychain copy stands in,
# one generic password per host under the service @service@.
#
# The token is one environment variable that the CLI sends to whichever
# host it talks to, so the host is resolved the way the CLI resolves
# it: --hostname, then the host variable, then for glab the
# repository's remote, which is all Orca gives for a local clone. A
# host with no keychain item gets no token rather than another host's.
token_var=@tokenVar@
host_var=@hostVar@
from_remote=@fromRemote@

host=
prev=
for arg in "$@"; do
  [ "$arg" = -- ] && break
  if [ "$prev" = --hostname ]; then
    host=$arg
  fi
  case $arg in
    --hostname=*) host=${arg#--hostname=} ;;
  esac
  prev=$arg
done

# A bare `auth status` probes every configured host with the one
# token, so it is narrowed to the host the token belongs to.
narrow=
if [ -z "$host" ] && [ "${1-}" = auth ] && [ "${2-}" = status ]; then
  narrow=1
fi

if [ -z "$host" ]; then
  host=${!host_var:-}
fi

# gh sends its token to github.com alone, so only glab, which follows
# the remote, takes the host from it.
if [ -z "$host" ] && [ -n "$from_remote" ]; then
  remote=$(git config --get remote.origin.url 2>/dev/null) || remote=
  # The authority ends at the first / ? or #, and userinfo at its last
  # @: cut in any other order, a remote such as
  # https://evil.example/@gitlab.com/x reads as gitlab.com.
  case $remote in
    *://*)
      authority=${remote#*://}
      authority=${authority%%[/?#]*}
      host=${authority##*@}
      host=${host%%:*}
      ;;
    *:*)
      authority=${remote%%:*}
      case $authority in
        */*) authority= ;;
      esac
      host=${authority##*@}
      ;;
  esac
  # Anything but a plain hostname gets no token.
  case $host in
    *[!A-Za-z0-9.-]*) host=invalid ;;
  esac
fi

host=${host:-@defaultHost@}

if [ -n "$narrow" ]; then
  set -- "$@" --hostname "$host"
fi

if [ -z "${!token_var:-}" ]; then
  if token=$(/usr/bin/security find-generic-password -s @service@ -a "$host" -w 2>/dev/null); then
    export "$token_var=$token"
  else
    echo "@tool@: no keychain item @service@ for $host" >&2
  fi
fi

exec @real@ "$@"

# Own secrets broker with a reference allowlist

Secrets stay in the Private and Employee vaults, which neither 1Password service
accounts nor Connect can reach, and a headless remote cannot run the desktop
app. So a remote reads a secret by asking the Mac: a secrets broker there runs
the real `op` behind Touch ID, and the remote's only `op` is a broker client
that reaches it through a second `RemoteForward` on the host's agent forwarder
connection (ADR-0007). There is one broker per NixOS host, with its own socket,
pty session, log and allowlist. The broker accepts exactly
`read [--no-newline] <ref> [--account <a>]` for the references that host's
configuration declares (its fnox profiles, `my.containers.registries`, tipctl's
item and the work layer's references, checked at evaluation time) and refuses
everything else, `inject`, `run` and `--out-file` included. It runs each read
inside one long-lived pty session, stdout to a pipe, so 1Password's own CLI
session decides when Touch ID appears; that session ends when the Mac's screen
locks and after one hour regardless of activity. It is written in Rust, one
binary for both ends, in `pkgs/`.

op-forward, the existing tool, was the alternative. It filters with a denylist
on the first argument only, which a leading global flag bypasses, and forwards
`op run` and file-writing options, so a compromised remote can read any item in
either vault and start programs on the Mac. It forwards no stdin, merges `op`'s
stderr into the value it returns, keeps a bearer token on every remote, holds
one token pair per daemon, and forces a pty per call so every secret is a
separate Touch ID prompt. Running it with an allowlisting `op` wrapper on its
daemon's `PATH` fixes the filter but not the rest. It is also a
single-maintainer project months old, so its maturity did not outweigh a broker
small enough to own.

## Consequences

- With no tty, `op` 2.41.1 prompts on every call; inside one pty session only
  the first call prompts. That holds when each `op` runs as a child of the
  session's long-lived leader, never as a new session leader on the pty. The
  broker's pty session is what keeps prompts rare, and the screen-lock and
  one-hour bounds are what keep an unattended agent from riding it.
- Unattended work on a remote gets no vault secrets once the session has ended:
  a read not approved within 60 s fails, and nothing is pushed at start-up.
- `_1password-cli` belongs to the macOS half; `programs._1password` is never
  enabled on NixOS, whose `/run/wrappers/bin` would shadow the broker client.
  Callers that run `op` by store path (tipctl, `docker-credential-op`) call it
  from `PATH`.
- A reference added anywhere in a host's configuration widens that host's
  allowlist, so the allowlist is reviewed by reviewing the configuration.

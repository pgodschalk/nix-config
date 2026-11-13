# GUI processes get session variables from an allowlist

A process started from the Dock or by an app inherits launchd's environment, not
a shell's, so a CLI an app spawns misses the session variables that make it
behave as in a shell: it recreates the dotfiles a state redirect exists to
prevent, reports telemetry or checks for updates, and reaches macOS's own SSH
agent or the wrong 1Password account. `modules/darwin/launchd-env.nix` exports
to launchd, together with `PATH` and the certificate bundle, only the GUI
variables: state redirects, tool locators, telemetry and update opt-outs,
`SSH_AUTH_SOCK`, `HELM_REGISTRY_CONFIG`, `REGISTRY_AUTH_FILE`, `OP_ACCOUNT`,
`AUBE_RUNTIME_INSTALLER`, `RESEND_CREDENTIAL_STORE` and
`RESEND_NO_UPDATE_NOTIFIER`. Every other session variable stays shell-only,
among them `EDITOR`, `PAGER`, `MANPAGER`, `BAT_*`, `FZF_*`, `MISE_COLOR_THEME`,
`STARSHIP_CONFIG`, `XDG_*_DIR`, `TERMINFO_DIRS`, `LC_ALL`, `LC_CTYPE`,
`PYTHONIOENCODING`, `MANROFFOPT` and `NH_DARWIN_FLAKE`: exporting them all would
put an interactive shell's settings into every GUI app's environment, and a
value that relies on shell expansion cannot pass through `launchctl setenv`
intact.

The module that sets a GUI variable exports it through
`my.launchd.extraVariables`, beside its setter, so the export cannot drift from
what is set and the work layer exports its own without this repository naming
them. `launchd-env.nix` names only what home-manager sets itself: the
`XDG_*_HOME` variables it exports and `TERMINFO_DIRS`, which stays shell-only.

Evaluation fails for an exported value holding `'`, `$` or a newline: nix-darwin
writes each value single-quoted into a `launchctl setenv` line, the login agent
reads one variable per line, and launchd never expands what a shell would. It
fails as well for a session variable whose value lies under the home directory
and that is neither exported nor declared shell-only, beside its setter, through
`my.launchd.shellOnlyVariables`, so a new state redirect cannot be left out of
the export unnoticed.

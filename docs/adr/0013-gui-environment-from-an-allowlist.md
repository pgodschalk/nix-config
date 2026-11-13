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
them. `launchd-env.nix` names only the `XDG_*_HOME` variables home-manager sets
itself.

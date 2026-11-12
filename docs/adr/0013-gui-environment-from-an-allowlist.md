# GUI processes get session variables from an allowlist

A process started from the Dock or by an app inherits launchd's environment, not
a shell's, so a CLI an editor spawns misses the variables that redirect its
state out of `$HOME` and recreates the dotfiles they exist to prevent.
`modules/darwin/launchd-env.nix` exports those redirects to launchd by name,
together with `PATH` and the certificate bundle, rather than every
`home.sessionVariables` entry. Exporting all of them would put dozens of
variables meant for shells, such as `EDITOR`, `PAGER`, `LC_ALL` and
`SSH_AUTH_SOCK`, into every GUI app's environment, and a value that relies on
shell expansion cannot pass through `launchctl setenv` intact. A module that
sets a redirect of its own adds its name through `my.launchd.extraVariables`, so
the work layer exports its own without this repository naming them.

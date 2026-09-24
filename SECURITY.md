# Security Policy

## Supported Versions

This repository is not released or versioned. It describes one machine, and the
only supported state is the current tip of the default branch; the `flake.lock`
there is the set of inputs actually in use. Older commits are history rather
than releases, and are not patched.

| Version        | Supported          |
| -------------- | ------------------ |
| Default branch | :white_check_mark: |
| Anything older | :x:                |

Vulnerabilities in the software this configuration installs belong upstream,
with nixpkgs or the project itself. What is in scope here is how this repository
configures that software.

## Reporting a Vulnerability

Report privately through [GitHub's security advisories][advisories] rather than
in a public issue. Include what the problem allows, the file or module it lives
in, and the steps to reproduce it.

Expect an acknowledgement within a week. Whether a report is accepted depends on
the reach of the problem: a weakened default that affects anyone who copies a
module is worth fixing, a setting that is merely not to your taste is not.
Either way you will be told which, and accepted reports are fixed on the default
branch with the reporter credited in the advisory unless you would rather not
be.

## What is not a vulnerability here

- **Credentials in the repository.** There are none. Secrets live in 1Password
  and reach a process through `fnox` or `op` at run time, so a committed file
  holds a reference and never a value. A real credential found in the tree or
  its history _is_ a valid report, and an urgent one.

  One exception is deliberate: the GitHub, Docker Hub and Cronometer MCP
  wrappers read their credentials from the login keychain, so an agent session
  raises no Touch ID prompt. Those items list `/usr/bin/security` as trusted, so
  any process running as the user can read them without a prompt; Claude Code
  denies itself the `security` commands that would.

- **The Secure Enclave SSH public keys** in `modules/home/ssh/authorized_keys`,
  the authentication key in `modules/home/darwin/ssh.nix` and the signing key in
  `modules/home/git.nix`. Public keys are public; the private halves cannot
  leave the Secure Enclave.
- **Pinned versions that have gone stale.** Open an ordinary issue. A pin
  covering a known CVE is worth reporting privately.
- **Anything requiring local access to an unlocked machine.** FileVault and the
  login keychain are the boundary this configuration assumes.

[advisories]: https://github.com/pgodschalk/nix-config/security/advisories/new

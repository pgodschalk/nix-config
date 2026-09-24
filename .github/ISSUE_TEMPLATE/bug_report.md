---
name: Bug report
about: Something in this configuration does not behave as declared
title: ""
labels: ""
assignees: ""
---

<!-- markdownlint-disable MD041 -->

**What goes wrong** A clear and concise description: a switch that fails, a
declared setting that does not apply, or a tool that behaves differently from
what its module says.

**Which part of the configuration** The module, package or host, e.g.
`modules/home/darwin/zed.nix` or `pkgs/dockerhub-mcp-server.nix`.

**To reproduce** The exact command and its output. Trim anything secret: prove a
credential by a property (length, prefix, hash) rather than its value, and treat
`list`, `getall` and `--format=json` output as containing one.

```console
darwin-rebuild build --flake /etc/nix-darwin
```

**Expected behaviour** What the configuration declares, and where it says so.

**Does it reproduce from a clean login shell?** An editor's or agent's terminal
carries a different environment, which is a common source of false symptoms.

```sh
/usr/bin/env -i HOME="$HOME" USER="$USER" TERM=xterm-256color \
  /bin/zsh -l -c '...'
```

**Machine** as reported by:

- macOS: <!-- sw_vers -->
- Nix: <!-- nix --version -->
- Generation: <!-- darwin-rebuild --list-generations | tail -1 -->
- Commit: <!-- git -C /etc/nix-darwin rev-parse --short HEAD -->

**Application-specific?** Some behaviour depends on which application ran the
command, because macOS grants file and folder access per app. Say whether it
differs between Ghostty, Terminal, Zed and Agentastic.dev.

**Additional context** Anything else relevant: a recent `nix flake update`, a
macOS update, or a setting changed by hand.

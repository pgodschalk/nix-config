# Deploy is a target build and one sudo, guarded by boot assessment

A NixOS host is deployed by our own Mac-side command, not by deploy-rs, Colmena
or `nixos-rebuild-ng --target-host`. The Mac evaluates the flake, the only place
the work layer exists, and copies the system's derivations to the host. The host
builds them, and one `sudo nixos-rebuild switch --store-path <toplevel>` runs on
the host itself. Every sudo on a host is one Touch ID, with no timestamp cache.
`nixos-rebuild-ng --target-host` elevates twice, once to set the profile and
once to switch, and it leaves a gap between evaluating and copying in which a
garbage collection on the Mac can delete the derivation. Run on the host, the
one elevated call still wraps `switch-to-configuration` in `systemd-run`, so the
activation finishes when the SSH session dies.

The session does die whenever a Deploy restarts `tailscaled`. With a Tailscale
SSH session open, `tailscaled` ignores SIGTERM until its stop timeout, so the
host leaves the tailnet for that long. With the default timeout that was 90
seconds. deploy-rs's magic rollback reverts unless it reconnects within 30
seconds, so it would undo every Deploy that touches `tailscaled`, and its
confirmation would cost more Touch IDs. Colmena offers no rollback at all.

Hosts guard against lockout differently. `tailscaled` stops within 5 seconds.
After a dropped session the command waits for the host to answer again, then
compares `/run/current-system` with the target. systemd-boot counts tries on
every new entry, and `boot-complete.target` requires a check that the host has
rejoined the tailnet, with a reboot on failure. A generation that boots but
never comes back on the tailnet is abandoned after three reboots, with nobody at
a console. Changes to networking, `tailscaled`, the firewall or the kernel
deploy with `boot` and a reboot, so that assessment covers them.

The costs:

- A Tailscale control-plane outage during a reboot makes a host reboot every few
  minutes until control returns.
- Nothing updates a host on its own: no pull, no CI deploy. Security fixes
  follow `nix flake update` on the Mac.
- Ending sessions after 5 seconds skips `tailscaled`'s graceful teardown and
  final log upload. Its state is written atomically as it changes, so nothing
  persisted is lost.

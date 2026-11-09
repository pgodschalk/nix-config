# Remotes are reached through Tailscale SSH, not OpenSSH

A NixOS host is logged into through Tailscale SSH, the server inside
`tailscaled`, under `accept` rules that admit only `patrick` from the tailnet's
member devices. OpenSSH on the tailnet was the alternative, and research
favoured it: every login would have been a Secretive signature and so a Touch ID
prompt, its sessions survive a `tailscaled` restart, and it has no
control-plane-dependent forwarding. Tailscale SSH was chosen anyway because it
needs no `sshd`, no `authorized_keys` and no host-key distribution on a remote,
the same on a NixOS host and in an ephemeral environment, and because the
tailnet identity is accepted as sufficient for login; every signature still
takes Touch ID through the forwarded agent. The costs are that anything running
as Patrick on a member device can log in without a prompt, that restarting
`tailscaled` ends every session, that `check` rules are unusable because Zed
times out on them, and that the tailnet policy becomes part of the
configuration: this repository exports it as a Terraform module of policy
fragments, which another repository applies. A host exposed beyond the tailnet
still runs OpenSSH on its public address alone, as the way back in when the
tailnet is down.

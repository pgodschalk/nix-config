# One Mac-owned connection per remote, whose forwarder never wakes a codespace

An ephemeral environment needs what a NixOS host needs from the Mac: the SSH
agent, for signing; the secrets broker, for vault secrets; and a channel for the
derivations of its target build, since there is no binary cache. ADR-0007 and
ADR-0008 give each NixOS host one standing connection for the first two. A
codespace gets the same: one connection the Mac opens through
`gh codespace ssh`'s ProxyCommand, started by `env up` and ended by `env down`.
It carries the agent and broker sockets to fixed paths under
`$XDG_STATE_HOME/remote/` (a container has no `/run/user`), Rex's socket back to
the Mac, and loopback forwards. Copying, building, activating and the Appearance
push multiplex over the same master. A codespace has neither pam_env nor a
systemd user environment, so `SSH_AUTH_SOCK` comes from home-manager's session
variables.

The codespace's configuration is built on the Mac against the work layer's stub,
on purpose: no employer configuration and no Employee-vault reference reaches a
codespace, which narrows ADR-0002 for ephemeral environments. Its broker allows
only the references that configuration declares, so Private-vault references
alone. Neither does a codespace see the host-only modules in
`modules/home/host/` (terraform, vagrant, the Docker client and its config, the
Rex service), which extends ADR-0003's split by directory: without a cache,
every package is built in the codespace on its first Deploy.

The alternatives were per-connection `ForwardAgent`, which goes stale in the
servers Zed and Agentastic leave running and carries no broker; a dotfiles
`install.sh` with a tailnet key or a Codespaces secret, which is a copy outside
the vaults and, without a cache, can install nothing but Nix; and joining
codespaces to the tailnet, which needs that key too. So ADR-0006's Tailscale SSH
covers NixOS hosts only, and a codespace is reached through OpenSSH behind `gh`.

A codespace differs from a host in five ways:

- Its sshd is logged into with Secretive's authentication key, so every new
  master costs a Touch ID. The forwarder detects a dropped connection with
  `ServerAliveInterval`, does not reconnect on its own, and after a drop
  notifies and stops.
- `gh` starts a stopped codespace whenever it connects, so the forwarder never
  connects to a codespace whose state is not `Available`, and leaves the idle
  timeout and its billing to GitHub. Other clients reach the codespace through
  an ssh `Include` that shares the forwarder's master; the forwarder removes it
  when it stops, so a later `ssh` fails fast instead of falling through to the
  ProxyCommand and waking the codespace.
- Its host keys live in `/etc/ssh`, which a rebuild regenerates, so they are not
  pinned: the Include, like `gh`'s own configuration, ignores known hosts, and
  the tunnel `gh` authenticates with its GitHub session is the trust boundary.
  Hosts keep their `KnownHostsCommand` pinning.
- That sshd does not unlink a stale socket. The master comes up first, removes
  both socket files and creates their `0700` directory over itself, and only
  then requests the forwards.
- A Deploy there is a home-manager activation, with no boot assessment; ADR-0010
  covers NixOS hosts. Its only privileged steps run through passwordless
  `sudo -n`: installing Determinate Nix with `--init none` when `/nix` is
  absent, and starting a root `nix-daemon` when none is running.

The costs:

- One Touch ID per `env up`, and one more for each of Zed and Agentastic, which
  open their own masters.
- Only processes that load the home-manager session variables find the agent, a
  weaker guarantee than ADR-0007's on a host.
- A codespace's identity rests on `gh` and the GitHub session behind it, not on
  a pinned host key.
- A deliberate connection from Zed or Agentastic still wakes a stopped
  codespace.
- Until `env up` has run, a codespace has nothing of this configuration. Once it
  is activated, without the connection it has no secrets and cannot sign:
  `git commit` fails rather than committing unsigned.
- Only the `codespace` user is built for; a devcontainer with another
  `remoteUser` is refused, as is an image without passwordless sudo.
- Unix-socket remote forwarding through the sshd `gh` starts is unprobed. If it
  fails, this decision is reopened for Codespaces.

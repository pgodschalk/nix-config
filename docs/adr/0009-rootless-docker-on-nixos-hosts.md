# Rootless Docker is the container engine on NixOS hosts

A NixOS host replaces OrbStack for remote development, so it needs a container
engine that devcontainers, Compose, BuildKit and Testcontainers treat as Docker.
Rootful Docker is the closest match to OrbStack and Codespaces, and it runs at
native network speed. But its socket is root-equivalent for every member of the
`docker` group. Every process running as `patrick` would then get root without
Touch ID, unattended agents included. That would make the remote root guard
meaningless: sudo approved through the forwarded agent with no timestamp cache,
and a root-owned `authorized_keys` on `public` hosts. Rootful Docker also
publishes ports through DNAT ahead of the INPUT firewall, so any host with a
public address, a `tailnet` cloud VM included, would expose them. So every NixOS
host runs Docker rootless instead. It keeps the same CLI, BuildKit, Compose and
image store. Published ports become user-space listeners that the firewall sees.
No host may enable the rootful daemon or a `docker` group, and an assertion
enforces that. Rootless Podman was the other candidate; it offers the same
isolation, but no BuildKit through the Docker API and weaker devcontainer and
Testcontainers parity.

Clients find the daemon through a root-owned `/run/docker.sock` symlink to
`/run/user/1000/docker.sock`, not through `DOCKER_HOST`. Tailscale SSH exec
sessions start the passwd shell with `-c` and no `XDG_RUNTIME_DIR`, so a session
variable reaches them only from bash, zsh or fish. The default path reaches
every process, along with the tools that hardcode it: the
`docker-outside-of-docker` Feature, Agentastic and Testcontainers.

The costs:

- Container networking runs through slirp4netns. It is slower than a bridge, and
  every client of a published port appears to the container as 127.0.0.1.
- IPv6 needs rootlesskit's experimental `--ipv6`.
- cpuset and I/O limits need `cpuset` and `io` delegated to `user@`.
- `docker-in-docker` and GPUs through CDI are untested under rootless on NixOS.
- The rootless daemon copies `/run` once at start, so a switch that first adds
  the symlink has to restart it.

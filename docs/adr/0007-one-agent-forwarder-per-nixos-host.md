# One agent forwarder per NixOS host owns the remote agent socket

Every signature and every sudo on a NixOS host is approved on the Mac, through
Secretive reached over SSH. Per-connection agent forwarding cannot carry that:
Tailscale SSH gives each `-A` session its own socket, which goes stale in the
long-lived servers Zed and Agentastic leave running. A fixed-path socket is the
alternative, but Tailscale SSH lets the newest connection that forwards a path
unlink the live socket and take it over, and never removes the file when a
forward ends. With Zed, Agentastic and a terminal each forwarding it over their
own ControlMasters, closing whichever connected last kills the agent for all of
them. So the Mac runs one launchd agent forwarder per NixOS host: a standing
`ssh -N` connection whose only job is
`RemoteForward /run/user/1000/ssh-agent.sock` to Secretive, reconnecting on
failure. The `Host` blocks every other client uses carry neither `ForwardAgent`
nor `RemoteForward`, and the host sets `SSH_AUTH_SOCK` to the fixed path itself,
through pam_env and the systemd user environment, so a process finds the agent
whichever connection, if any, it was born under. ssh-agent-switcher, which
cannot see Tailscale SSH's sockets, and `SetEnv` from the Mac, which reaches
nothing started outside SSH, were the alternatives.

The costs: the host pins `patrick`'s uid and enables linger, since Tailscale SSH
creates no parent directory and the path is written out on the Mac, where no
`ssh_config` token gives the remote uid; one extra connection stays open per
host; and while the Mac is asleep or offline the socket is dead, so signing and
sudo fail closed rather than falling back. A server started before the change,
such as Zed's, keeps its old path until it is restarted once.

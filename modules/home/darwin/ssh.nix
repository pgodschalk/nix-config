{
  config,
  lib,
  pkgs,
  ...
}:
let
  # SecretAgent is sandboxed, so its socket lives inside the agent's
  # container. Secure Enclave keys cannot be exported or migrated, so
  # each machine gets its own and the public keys are published by hand.
  secretiveData = "${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data";
  secretiveSocket = "${secretiveData}/socket.ssh";

  # Secretive names public keys by the secret's id, so the filenames say
  # nothing. By the name shown in its UI:
  #   id_ecdsa          aa76ac8c…  authentication
  #   id_ecdsa_signing  2a9fb71e…  signing
  #   id_mldsa          3762693a…  authentication, ML-DSA
  #   id_mldsa_signing  bdb1067a…  signing, ML-DSA
  secretiveAuthKey = "${secretiveData}/PublicKeys/aa76ac8cc8634906d882a1a967493975.pub";

  # Claude Code probes GitHub's SSH auth on startup with `ssh -T -o
  # BatchMode=yes …`, and BatchMode suppresses password prompts rather
  # than agent signatures, so every launch raised a Touch ID prompt.
  #
  # The probe's answer decides only whether a marketplace source written
  # in SSH form is kept or rewritten to HTTPS, so denying it the agent
  # costs one HTTPS fetch.
  #
  # Two conditions, and narrowing to `-T` rather than to Claude Code
  # alone keeps real GitHub SSH on the Secure Enclave key: ssh's parent
  # process is `claude` itself, and `ps -o args= -p $PPID` prints ssh's
  # own argv, where `-T` is the probe's signature -- git's transport
  # always asks for git-upload-pack or git-receive-pack.
  claudeGitHubAuthProbe = pkgs.writeShellScript "ssh-is-claude-github-auth-probe" (
    builtins.readFile ./ssh/claude-probe.sh
  );
in
{
  # 1Password's agent is also running but is deliberately not the
  # default, since Secure Enclave keys cannot be exported. A host that
  # needs a portable key opts in with its own `IdentityAgent`, quoted
  # because that path contains a space.
  programs.ssh = {
    # OrbStack generates and rewrites its file, which is entirely
    # self-contained. home-config is hand-maintained and deliberately
    # outside Nix; it is named `<context>-config` so it ends in
    # "config", the suffix Zed's SSH Config extension matches on.
    includes = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin [
      "~/.orbstack/ssh/config"
      "~/.ssh/home-config"
    ];

    settings = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      # Only this machine can read the macOS light/dark setting, so the
      # other end applies whatever APPEARANCE says. The server must
      # allow it with `AcceptEnv APPEARANCE`.
      "*".SendEnv = [ "APPEARANCE" ];

      # Ordered ahead of "github.com", and so ahead of "*", because ssh
      # keeps the first value it obtains for a keyword. With no agent
      # to ask, the probe fails in milliseconds and the caller reads
      # that as "SSH not configured".
      #
      # It prints an "UNPROTECTED PRIVATE KEY FILE" warning on the way,
      # because ssh falls to the "*" block's IdentityFile and finds a
      # mode-0644 public key. That cannot be silenced from here --
      # IdentityFile is additive, so `IdentityFile none` is appended
      # rather than replacing the list -- and is cosmetic, since the
      # caller matches stderr against "successfully authenticated".
      #
      # Named rather than spelled out as the attribute name, because an
      # attribute name carries no string context and Nix refuses one
      # that interpolates a store path. `header` is a value.
      claude-github-auth-probe = lib.hm.dag.entryBefore [ "github.com" ] {
        header = ''Match host github.com exec "${claudeGitHubAuthProbe}"'';
        IdentityAgent = "none";
      };

      # Merged into the portable "*" block in modules/home/ssh.nix.
      "*" = {
        IdentityAgent = secretiveSocket;

        # What `IdentitiesOnly` in the portable module needs to point
        # at: on its own it makes ssh fall back to the default identity
        # files, none of which exist here, and offer nothing at all --
        # the agent's keys included. Secretive's own copy, so a rotation
        # needs no re-syncing. Needs a TCC grant.
        IdentityFile = secretiveAuthKey;
      };
    };
  };

  # For tools that read SSH_AUTH_SOCK rather than ssh_config.
  home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    SSH_AUTH_SOCK = secretiveSocket;
  };
}

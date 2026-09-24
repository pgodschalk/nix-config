{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
{
  programs.ssh = {
    enable = true;

    # home-manager's historical defaults for "*" warn if left enabled.
    enableDefaultConfig = false;

    # home-manager emits these as one Include at the top of the file,
    # ahead of every Host block, which is the placement that matters:
    # ssh keeps the first value it obtains for a keyword, so an included
    # file can override the "*" block below and not the other way round.
    # A missing Include is not an error, so an optional file needs no
    # guard. The macOS-only includes are in modules/home/darwin/ssh.nix.
    includes = [ ];

    settings = {
      # Getting this wrong fails with "repository not found" rather than
      # an auth error.
      "github.com".User = "git";
      "gitlab.com".User = "git";

      # Keywords alphabetical, as ssh_config(5) lists them; only the
      # order of the blocks is semantic. modules/home/darwin/ssh.nix
      # merges the Secure Enclave keys into this same block.
      "*" = {

        Ciphers = lib.concatStringsSep "," [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];

        # Only affects entries written from now on.
        HashKnownHosts = true;

        # The RSA entries are signature algorithm names, so they do not
        # appear in `ssh -Q key`; check against
        # `ssh -Q HostKeyAlgorithms`.
        HostKeyAlgorithms = lib.concatStringsSep "," [
          "ssh-ed25519-cert-v01@openssh.com"
          "ssh-ed25519"
          "sk-ssh-ed25519-cert-v01@openssh.com"
          "sk-ssh-ed25519@openssh.com"
          "rsa-sha2-512-cert-v01@openssh.com"
          "rsa-sha2-256-cert-v01@openssh.com"
          "rsa-sha2-512"
          "rsa-sha2-256"
          "ecdsa-sha2-nistp521-cert-v01@openssh.com"
          "ecdsa-sha2-nistp384-cert-v01@openssh.com"
          "ecdsa-sha2-nistp256-cert-v01@openssh.com"
          "ecdsa-sha2-nistp521"
          "ecdsa-sha2-nistp384"
          "ecdsa-sha2-nistp256"
        ];

        # Needs an `IdentityFile` to name something, or ssh falls back
        # to the default `~/.ssh/id_*` paths. macOS names Secretive's
        # public key from modules/home/darwin/ssh.nix; a Linux host has
        # to name its own.
        IdentitiesOnly = true;

        # An unknown algorithm name here is not ignored -- it stops ssh
        # from starting -- so check any addition against `ssh -Q`. Both
        # post-quantum entries are hybrids with X25519, so neither is a
        # downgrade if the PQ half is broken; sntrup761 stays because
        # more servers speak it.
        KexAlgorithms = lib.concatStringsSep "," [
          "mlkem768x25519-sha256"
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256@libssh.org"
          "curve25519-sha256"
          "ecdh-sha2-nistp521"
          "ecdh-sha2-nistp384"
          "ecdh-sha2-nistp256"
          "diffie-hellman-group-exchange-sha256"
        ];

        MACs = lib.concatStringsSep "," [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
          "hmac-sha2-512"
          "hmac-sha2-256"
          "umac-128@openssh.com"
        ];
      };
    };
  };

  # Keys accepted for incoming SSH. Remote Login is off on the Mac, so
  # nothing uses it there yet.
  #
  # After linkGeneration, which removes the link earlier generations
  # made here.
  home.activation.sshAuthorizedKeys = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    substituteFile ./ssh/install-authorized-keys.sh {
      coreutils = "${pkgs.coreutils}";
      dir = lib.escapeShellArg "${config.home.homeDirectory}/.ssh";
      src = "${./ssh/authorized_keys}";
      dst = lib.escapeShellArg "${config.home.homeDirectory}/.ssh/authorized_keys";
    }
  );
}

{ lib, pkgs, ... }:
{
  # `jq` is aliased to jaq in modules/home/nushell.nix, which binds in
  # interactive Nushell only; anything here needing jq's exact behaviour
  # calls pkgs.jq by store path.
  home.packages = [
    pkgs.jaq

    # For `.jq` filter files rather than the `jq` command.
    pkgs.jq-lsp
  ]
  # macOS ships its own jq at /usr/bin/jq, so installing one there would
  # only shadow an identical binary.
  ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.jq ];
}

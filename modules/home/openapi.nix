{ pkgs, ... }:
{
  # Disabled globally and enabled per project in modules/home/zed.nix:
  # the extension claims the whole of YAML and JSON, and vacuum reports
  # an error on anything that is not an API description, so left on it
  # marks every package.json and Kubernetes manifest.
  home.packages = [ pkgs.vacuum-go ];

  # Helix needs no counterpart: its per-language `language-servers`
  # lists are explicit, so a defined but unlisted server never runs.
}

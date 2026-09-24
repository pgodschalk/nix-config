{ pkgs, ... }:
{
  # yq-go (mikefarah). `pkgs.yq` is kislyuk/yq, a Python wrapper around
  # jq, and its expression language differs from this one's.
  home.packages = [ pkgs.yq-go ];
}

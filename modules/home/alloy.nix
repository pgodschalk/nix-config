{ pkgs, ... }:
{
  # `alloy fmt` ships only inside the whole collector.
  home.packages = [ pkgs.grafana-alloy ];
}

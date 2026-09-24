{ pkgs, ... }:
{
  # path-server is published for aarch64-apple-darwin alone, so unlike
  # the wheel-based servers in modules/home/python-lsps-wheels.nix it
  # cannot be selected per platform. It completes filesystem paths in
  # any buffer, despite arriving through the Python pass.
  home.packages = [ (pkgs.callPackage ../../../pkgs/path-server.nix { }) ];
}

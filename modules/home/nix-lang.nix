{ pkgs, ... }:
{
  home.packages = [
    pkgs.nixd

    # Load-bearing: nixd formats by shelling out to nixfmt, and without
    # it a formatting request comes back null rather than an error.
    pkgs.nixfmt
  ];
}

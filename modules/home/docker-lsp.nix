{ pkgs, ... }:
{
  home.packages = [
    pkgs.dockerfile-language-server
    pkgs.docker-language-server
  ];
}

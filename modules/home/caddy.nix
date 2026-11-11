{ pkgs, ... }:
{
  # `caddy fmt` ships only inside the whole server.
  home.packages = [ pkgs.caddy ];
}

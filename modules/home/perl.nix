{ lib, pkgs, ... }:
{
  home.packages = [
    pkgs.perlnavigator
    pkgs.perlPackages.PerlTidy
    pkgs.perlPackages.PerlCritic
  ]
  # macOS ships /usr/bin/perl, and perltidy carries its own interpreter
  # in its shebang.
  ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.perl ];
}

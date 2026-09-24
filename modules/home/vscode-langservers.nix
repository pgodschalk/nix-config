{ pkgs, ... }:
{
  # One package, four servers: CSS, JSON, HTML and ESLint.
  home.packages = [ pkgs.vscode-langservers-extracted ];
}

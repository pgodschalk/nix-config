{ config, pkgs, ... }:
{
  home.sessionVariables.ANSIBLE_HOME = "${config.xdg.dataHome}/ansible";

  home.packages = [
    pkgs.ansible

    # Not optional: ansible-language-server runs ansible-lint for its
    # diagnostics and falls back to a far weaker syntax check without
    # it.
    pkgs.ansible-lint

    pkgs.ansible-language-server
  ];
}

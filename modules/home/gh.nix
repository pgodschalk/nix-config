{
  lib,
  ...
}:
{
  programs.gh = {
    enable = true;

    settings = {

      git_protocol = "ssh";

      # `--style=plain`, not `--style-plain`: bat exits non-zero on the
      # latter, and as a pager that swallows gh's output.
      pager = "bat --style=plain";

      color_labels = "enabled";

      # Makes gh pick a 4-bit ANSI palette by terminal background
      # instead of hardcoded truecolor, so it follows the appearance
      # with no theme file.
      accessible_colors = "enabled";

      telemetry = "disabled";
    };
  };

  # fnox's global configuration, loaded everywhere including directories
  # with no fnox.toml. Managed here rather than by
  # `fnox provider add --global`, which cannot write to a store symlink.
  xdg.configFile."fnox/config.toml".text = builtins.readFile ./gh/fnox.toml;

  # Resolves on first use and caches in the shell's environment, so a
  # shell that never runs gh pays nothing.
  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./gh/gh.nu);
}

{ ... }:
{
  # asciinema writes `install-id` into this directory, so only the one
  # file is claimed and never the directory.
  xdg.configFile."asciinema/defaults.toml".source = ./asciinema/defaults.toml;
}

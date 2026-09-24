{ pkgs, ... }:
{
  # No config is written: macchina hardcodes ~/.config/macchina and
  # ignores XDG_CONFIG_HOME, so writing one would create a dotdir. Its
  # defaults emit ANSI palette slots, so it follows the appearance
  # without a theme.
  home.packages = [ pkgs.macchina ];
}

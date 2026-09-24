{ pkgs, ... }:
{
  home.packages = [ pkgs.codebook ];

  # US and British English. `en_gb` stops `visualise` being flagged; the
  # cost is that a US/GB inconsistency inside one document is no longer
  # caught.
  #
  # `nl_nl` is absent on purpose: with it, an English typo that happens
  # to spell a Dutch word goes unreported. Dutch belongs in a
  # codebook.toml in the project written in Dutch.
  xdg.configFile."codebook/codebook.toml".source = ./spellcheck/codebook.toml;
}

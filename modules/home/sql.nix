{ pkgs, ... }:
{
  # pgfmt and its `pgfmt-1nl` wrapper come from
  # modules/home/formatters.nix, with the other `-1nl` wrappers.
  home.packages = [
    # Nothing uses sql-formatter by default; it is what a project on
    # another dialect overrides to, since pgfmt exits 1 on MySQL
    # backticks.
    pkgs.sql-formatter

    # Needs no database connection to report syntax diagnostics; a live
    # one buys schema-aware completion and is a per-project matter. The
    # editors invoke it as `lsp-proxy`.
    pkgs.postgres-language-server
  ];

  # SQL indents with tabs in both editors because pgfmt does and has no
  # option not to -- no flags, no config file.
}

{ config, pkgs, ... }:
{
  home.sessionVariables = {
    # Two variables because the halves belong in different trees: GOPATH
    # is data, GOMODCACHE is a regenerable cache that grows to
    # gigabytes. GOCACHE already defaults to ~/Library/Caches/go-build.
    GOMODCACHE = "${config.xdg.cacheHome}/go/mod";
    GOPATH = "${config.xdg.dataHome}/go";
  };

  home.packages = [
    pkgs.gopls

    # A floor: gopls refuses to load a workspace with no `go` on PATH,
    # and Zed spawns language servers without mise's PATH. A repo
    # pinning its own Go through mise still wins in a shell.
    pkgs.go

    pkgs.delve
  ];

  # gopls publishes no lint-grade diagnostics until `staticcheck` is on,
  # which both editors set. golangci-lint is not installed: Zed cannot
  # start a server no extension declares, so it would lint Go in Helix
  # only.
}

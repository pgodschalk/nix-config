{ pkgs, ... }:
{
  home.packages = [
    # Ships as the `svelteserver` binary and bundles the prettier and
    # prettier-plugin-svelte it formats through.
    pkgs.svelte-language-server
  ];
}

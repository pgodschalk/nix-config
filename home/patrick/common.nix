{ apps, pkgs, ... }:
{
  imports = [
    ../../modules/home/age.nix
    ../../modules/home/aichat.nix
    ../../modules/home/alloy.nix
    ../../modules/home/ansible.nix
    ../../modules/home/asciinema.nix
    ../../modules/home/astro.nix
    ../../modules/home/aube.nix
    ../../modules/home/awk.nix
    ../../modules/home/bat.nix
    ../../modules/home/biome.nix
    ../../modules/home/bun.nix
    ../../modules/home/c-cpp.nix
    ../../modules/home/claude-code.nix
    ../../modules/home/claude-skills.nix
    ../../modules/home/cmake.nix
    ../../modules/home/commit-messages.nix
    ../../modules/home/completions.nix
    ../../modules/home/containers.nix
    ../../modules/home/coverage.nix
    ../../modules/home/css.nix
    ../../modules/home/dependencies.nix
    ../../modules/home/docker-lsp.nix
    ../../modules/home/emmet.nix
    ../../modules/home/fd.nix
    ../../modules/home/fnox.nix
    ../../modules/home/formatters.nix
    ../../modules/home/fzf.nix
    ../../modules/home/gh.nix
    ../../modules/home/git.nix
    ../../modules/home/glab.nix
    ../../modules/home/go.nix
    ../../modules/home/graphql.nix
    ../../modules/home/hcp.nix
    ../../modules/home/helix.nix
    ../../modules/home/helm.nix
    ../../modules/home/huggingface.nix
    ../../modules/home/jaq.nix
    ../../modules/home/java.nix
    ../../modules/home/js-debug.nix
    ../../modules/home/jujutsu.nix
    ../../modules/home/less.nix
    ../../modules/home/local-bin.nix
    ../../modules/home/locale.nix
    ../../modules/home/macchina.nix
    ../../modules/home/markdown.nix
    ../../modules/home/mcp.nix
    ../../modules/home/mise.nix
    ../../modules/home/moor.nix
    ../../modules/home/nh.nix
    ../../modules/home/nix-lang.nix
    ../../modules/home/nodejs.nix
    ../../modules/home/nomad.nix
    ../../modules/home/nushell.nix
    ../../modules/home/onepassword.nix
    ../../modules/home/openapi.nix
    ../../modules/home/options.nix
    ../../modules/home/oxc.nix
    ../../modules/home/perl.nix
    ../../modules/home/powershell.nix
    ../../modules/home/procs.nix
    ../../modules/home/python-lsps-wheels.nix
    ../../modules/home/python-lsps.nix
    ../../modules/home/python.nix
    ../../modules/home/resend.nix
    ../../modules/home/ripgrep.nix
    ../../modules/home/ruby.nix
    ../../modules/home/sentry.nix
    ../../modules/home/shell-script.nix
    ../../modules/home/spellcheck.nix
    ../../modules/home/sql.nix
    ../../modules/home/ssh.nix
    ../../modules/home/starship.nix
    ../../modules/home/swift.nix
    ../../modules/home/systemd.nix
    ../../modules/home/tailwind.nix
    ../../modules/home/telemetry.nix
    ../../modules/home/terraform.nix
    ../../modules/home/tipctl.nix
    ../../modules/home/tlrc.nix
    ../../modules/home/toml.nix
    ../../modules/home/typescript.nix
    ../../modules/home/uutils.nix
    ../../modules/home/uv.nix
    ../../modules/home/vim.nix
    ../../modules/home/vscode-langservers.nix
    ../../modules/home/yaml-ci.nix
    ../../modules/home/yaml.nix
    ../../modules/home/yq.nix
    ../../modules/home/yt-dlp.nix
    ../../modules/home/zoxide.nix
    ../../modules/home/zsh.nix
  ];

  # Packages that should be installed to the user profile.
  home.packages = apps.packages pkgs;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage when a
  # new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the
  # Home Manager release notes for a list of state version changes in
  # each release.
  # @VERSION
  # https://nix-community.github.io/home-manager/release-notes/release-notes.html
  home.stateVersion = "26.11";
}

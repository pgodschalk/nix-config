{ lib, pkgs, ... }:
let
  json = (pkgs.formats.json { }).type;
in
{
  # Options whose consumer is macOS-only, declared where every platform
  # sees them: a module that is not imported on Linux cannot declare the
  # option the work layer sets, and the evaluation would fail on "option
  # does not exist" rather than quietly doing nothing.
  #
  # An option consumed by a portable module stays in that module.
  options.my = {

    # modules/home/darwin/agentastic.nix
    agentastic.settings = lib.mkOption {
      type = json;
      default = { };
      description = "Agentastic.dev settings merged into its settings.json.";
    };

    # modules/home/darwin/mas.nix
    masApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = { };
      description = "Mac App Store apps to install, name to App Store id.";
    };

    # modules/home/mcp.nix, whose macOS-only servers are added by
    # modules/home/darwin/mcp.nix.
    mcp.servers = lib.mkOption {
      type = json;
      default = { };
      description = "MCP servers registered for every agent that reads a JSON config.";
    };

    # The themes are working copies rather than store paths, because
    # dracula-pro is paid and is not redistributed here, so a host
    # without the checkouts must not declare symlinks into them.
    theme.dracula = {
      pro = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/patrick/Developer/github.com/dracula-pro/dracula-pro";
        description = "Path to a dracula-pro checkout, or null.";
      };
      extras = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/patrick/Developer/github.com/pgodschalk/dracula-pro-extras";
        description = "Path to a dracula-pro-extras checkout, or null.";
      };
    };

    # modules/home/darwin/zed.nix
    zed.extraSettings = lib.mkOption {
      type = json;
      default = { };
      description = "Extra Zed settings, merged into the rendered settings.json.";
    };
  };
}

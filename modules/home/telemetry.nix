{ ... }:
{
  # Every telemetry and usage-reporting opt-out in one place.
  home.sessionVariables = {

    # HashiCorp's checkpoint service, called on startup by terraform,
    # terraform-ls, packer, vault, consul and nomad. It is also what
    # creates ~/.terraform.d, whose only contents are its cache and a
    # persistent random id.
    CHECKPOINT_DISABLE = "1";

    CLOUDSDK_CORE_DISABLE_USAGE_REPORTING = "true";
    DISABLE_AUTOUPDATER = "1";

    # Claude Code's telemetry stays on, because feature-flag evaluation
    # runs through the same client and Remote Control refuses without
    # it. Four variables each produce that refusal and must all stay
    # unset: CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC,
    # DISABLE_TELEMETRY, DISABLE_GROWTHBOOK and DO_NOT_TRACK.
    #
    # The cost of leaving DO_NOT_TRACK unset is that bun's telemetry is
    # on, that being the only opt-out bun carries, and that this file no
    # longer covers a tool added later that adopts the standard.
    DISABLE_ERROR_REPORTING = "1";

    HF_HUB_DISABLE_TELEMETRY = "1";
    HF_HUB_DISABLE_UPDATE_CHECK = "1";

    # A strict `=== "1"` comparison, not truthiness. Its telemetry also
    # writes a `telemetry-id` file into the CLI's config directory.
    RESEND_TELEMETRY_DISABLED = "1";
  };

  # Not here because the setting is a config key rather than a variable:
  # gh and glab (each writes it in its own module, since the config
  # default is on and a nixpkgs wrapper is not a contract), and Zed's
  # telemetry.diagnostics and telemetry.metrics.
}

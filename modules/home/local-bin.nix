{ ... }:
{
  # `$HOME` rather than `~`: the value is spliced into a double-quoted
  # shell context, and home-manager escapes a tilde into a literal.
  #
  # sessionPath prepends, so a binary here outranks the profile's. It
  # reaches shells only; GUI apps read launchd.user.envVariables.
  home.sessionPath = [ "$HOME/.local/bin" ];
}

{ ... }:
{
  # macOS leaves LANG and every LC_* unset in a login shell, so a
  # program that reads the environment rather than asking libc guesses
  # ASCII.
  home.sessionVariables = {
    # LC_ALL overrides every category, so collation, time and number
    # formats become en_US too and the Dutch regional formats do not
    # reach the command line.
    LC_ALL = "en_US.UTF-8";

    LC_CTYPE = "en_US.UTF-8";

    # Python otherwise takes its encoding from the locale and dies on
    # the first non-ASCII byte it prints.
    PYTHONIOENCODING = "UTF-8";
  };
}

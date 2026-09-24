# shellcheck shell=bash
# masInstalled and masFailed belong to install.sh, which this is spliced
# into.
# shellcheck disable=SC2154
if printf '%s\n' "$masInstalled" | cut -d' ' -f1 | grep -qx @id@; then
  verboseEcho "Mac App Store app already installed: "@label@
else
  _iNote "Installing Mac App Store app %s" @label@

  if ! run @mas@ install @id@; then
    masFailed+="  "@label@$'\n'
  fi
fi

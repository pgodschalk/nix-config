# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out"

for v in pro alucard; do
  substitute @gitconfigTemplate@ "$out/$v.gitconfig" \
    --replace-fail '@variant@' "$v"

  case $v in
    pro)
      background=dark
      lumen_theme=dracula
      moor_style=dracula
      ;;
    alucard)
      background=light
      lumen_theme=catppuccin-latte
      moor_style=tango
      ;;
  esac

  substitute @envTemplate@ "$out/$v.env" \
    --replace-fail '@variant@' "$v" \
    --replace-fail '@background@' "$background" \
    --replace-fail '@lumenTheme@' "$lumen_theme" \
    --replace-fail '@moorStyle@' "$moor_style" \
    --replace-fail '@out@' "$out"
done

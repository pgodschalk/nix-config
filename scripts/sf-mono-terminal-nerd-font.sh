# shellcheck shell=bash

dest="$HOME/Library/Fonts/SFMonoTerminalNerdFont-Regular.ttf"
src=@src@

if [ ! -r "$src" ]; then
  echo "error: $src is missing" >&2
  exit 1
fi

if [ -f "$dest" ] && [ "$dest" -nt "$src" ]; then
  echo "  already built and newer than the system font; nothing to do"
  exit 0
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/sfmono.XXXXXX")
trap 'rm -rf "$work"' EXIT

# SF Mono Terminal is a variable font, which the Nerd Fonts patcher
# cannot handle, so it is instanced to its named Regular master first.
echo "  instancing the Regular master..."
python3 -m fontTools.varLib.instancer "$src" \
  "wght=400" "YAXS=324.3341064453125" \
  -o "$work/SFMonoTerminal-Regular.ttf" >/dev/null

echo "  patching with Nerd Fonts glyphs (this takes about a minute)..."
nerd-font-patcher --complete --outputdir "$work" \
  "$work/SFMonoTerminal-Regular.ttf" >/dev/null

mkdir -p "$HOME/Library/Fonts"
cp "$work/SFMonoTerminalNerdFont-Regular.ttf" "$dest"
echo "  installed $dest"
echo "  family: SFMonoTerminal Nerd Font"

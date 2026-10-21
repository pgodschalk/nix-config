"""Install Ghostty theme files as Rex custom themes.

Rex keeps its custom themes in the `Workspace.customThemes` default: a
JSON array stored as plist data. This builds the entry Rex's own
"Import Theme File" action would, and replaces entries by id, so themes
added in the app are kept and a re-run changes nothing.
"""

import argparse
import json
import plistlib
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

KEY = "Workspace.customThemes"

COLOURS = {
    "background": "background",
    "foreground": "foreground",
    "cursor-color": "cursor",
    "cursor-text": "cursorText",
    "selection-background": "selectionBackground",
    "selection-foreground": "selectionForeground",
}

# NSDate's reference date, 2001-01-01, as a Unix timestamp.
APPLE_EPOCH = 978307200


def rgb(value: str) -> dict[str, Any]:
    """Convert a `#RRGGBB` Ghostty colour to Rex's colour record."""
    hex_digits = value.strip().removeprefix("#")
    if len(hex_digits) != 6:
        raise ValueError(f"not a #RRGGBB colour: {value!r}")
    red, green, blue = (
        int(hex_digits[i : i + 2], 16) / 255 for i in (0, 2, 4)
    )
    return {
        "red": red,
        "green": green,
        "blue": blue,
        "alpha": 1,
        "colorSpace": "srgb",
    }


def palette(path: Path) -> dict[str, Any]:
    """Read a Ghostty theme file into Rex's `palette` record."""
    colours: dict[str, dict[str, Any]] = {}
    ansi: dict[int, dict[str, Any]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        key, sep, value = line.partition("=")
        key = key.strip()
        if not sep or key.startswith("#"):
            continue
        if key == "palette":
            index, _, colour = value.partition("=")
            ansi[int(index)] = rgb(colour)
        elif key in COLOURS:
            colours[COLOURS[key]] = rgb(value)

    missing = [k for k in COLOURS.values() if k not in colours]
    missing += [f"palette {i}" for i in range(16) if i not in ansi]
    if missing:
        raise ValueError(f"{path}: missing {', '.join(missing)}")

    return {
        **colours,
        "ansi": [ansi[i] for i in range(16)],
        "paletteGenerate": True,
        "paletteHarmonious": True,
        "paletteBase": {},
        "paletteOverrides": {},
    }


def read_themes(domain: str) -> list[dict[str, Any]]:
    """Return the custom themes currently stored in `domain`."""
    exported = subprocess.run(
        ["/usr/bin/defaults", "export", domain, "-"],
        check=True,
        capture_output=True,
    ).stdout
    stored = plistlib.loads(exported).get(KEY)
    return json.loads(stored) if stored else []


def main() -> int:
    """Parse the arguments and merge the themes into Rex's defaults."""
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--domain", default="com.superlogical.rex")
    ap.add_argument(
        "--theme",
        nargs=3,
        action="append",
        required=True,
        metavar=("ID", "APPEARANCE", "PATH"),
        help="a theme to install; APPEARANCE is light or dark",
    )
    args = ap.parse_args()

    themes = read_themes(args.domain)
    by_id = {t.get("id"): t for t in themes}

    for theme_id, appearance, file in args.theme:
        path = Path(file)
        if not path.is_file():
            print(
                f"warning: {path} is missing; Rex theme skipped",
                file=sys.stderr,
            )
            continue
        entry = {
            "id": theme_id,
            "name": path.name,
            "appearance": appearance,
            "source": {"ghosttyFile": {"fileName": path.name}},
            "createdAt": by_id.get(theme_id, {}).get(
                "createdAt", time.time() - APPLE_EPOCH
            ),
            "palette": palette(path),
        }
        if theme_id in by_id:
            themes[themes.index(by_id[theme_id])] = entry
        else:
            themes.append(entry)
        by_id[theme_id] = entry

    data = json.dumps(themes, separators=(",", ":")).encode()
    subprocess.run(
        ["/usr/bin/defaults", "import", args.domain, "-"],
        input=plistlib.dumps({KEY: data}),
        check=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

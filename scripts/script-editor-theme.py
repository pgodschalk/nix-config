"""Apply a colour scheme to Apple's Script Editor.

Script Editor keeps its syntax styles in two per-language domains, as
arrays of dictionaries whose NSFont and NSColor values are legacy
`streamtyped` NSArchiver blobs:

    com.apple.applescript    AppleScriptSourceAttributes    18 styles
    com.apple.JavaScriptOSA  JavaScriptSourceAttributes     18 styles,
                                                             6 usable

Neither is reachable with `defaults` and the blobs are not safely
hand-editable, so Cocoa does the archiving.

Both arrays share the AppleScript ordering. JavaScript greys out the
twelve categories that read an application dictionary, so only six of
its slots matter, and they sit at their AppleScript index positions
rather than at 0-5.

Script Editor stores ONE colour set and derives the dark appearance from
it at display time, so the light values are what get written; the dark
palette would be adapted a second time.
"""

import argparse
import json
import plistlib
import subprocess
import sys
from typing import Any

# pyobjc populates these namespaces at import time through
# `objc.loadBundle`, so no static checker can see their members.
from AppKit import NSColor, NSFont  # ty: ignore[unresolved-import]
from Foundation import NSArchiver  # ty: ignore[unresolved-import]

SOURCES = {
    "applescript": ("com.apple.applescript", "AppleScriptSourceAttributes"),
    "javascript": ("com.apple.JavaScriptOSA", "JavaScriptSourceAttributes"),
}


def face_suffix(weight: str, slant: str) -> str:
    """Return the PostScript face suffix for a weight and slant."""
    bold = weight.lower() == "bold"
    italic = slant.lower() == "italic"

    if bold and italic:
        return "-BoldItalic"
    if bold:
        return "-Bold"
    if italic:
        return "-Italic"

    return "-Regular"


def colour_from_hex(value: str) -> NSColor:
    """Return an sRGB NSColor for a `#rrggbb` string.

    sRGB rather than calibrated RGB, which is Generic RGB and would shift
    every theme colour.
    """
    value = value.lstrip("#")
    r, g, b = (int(value[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    return NSColor.colorWithSRGBRed_green_blue_alpha_(r, g, b, 1.0)


def load_theme(path: str) -> dict:
    """Evaluate the Nix theme at `path` and return it as data."""
    out = subprocess.run(
        ["nix", "eval", "--file", path, "--json"],
        check=False,
        capture_output=True,
        text=True,
    )

    if out.returncode != 0:
        print(
            f"error: could not evaluate {path}\n{out.stderr}", file=sys.stderr
        )
        sys.exit(1)

    return json.loads(out.stdout)


def apply_language(
    theme: dict[str, Any], language: str, args: argparse.Namespace
) -> bool:
    """Write the theme into one language's domain; return whether it did."""
    domain, key = SOURCES[language]
    # Both arrays use the AppleScript ordering.
    order = theme["languages"]["applescript"]["order"]
    categories = theme["languages"][language]["categories"]

    exported = subprocess.run(
        ["defaults", "export", domain, "-"], check=False, capture_output=True
    )
    plist = plistlib.loads(exported.stdout) if exported.returncode == 0 else {}
    entries = plist.get(key)

    if not entries:
        print(
            f"  {domain}: no {key} yet — change one style by hand in Script "
            f"Editor's Formatting tab for this language, then re-run"
        )
        return False

    print(f"  {domain} ({language}):")
    out, changed = [], False

    for index, entry in enumerate(entries):
        entry = dict(entry)
        name = order[index] if index < len(order) else None
        spec = categories.get(name) if name else None

        if spec is None:
            out.append(entry)  # greyed-out JavaScript slot: leave alone
            continue

        family = args.family or spec["family"]
        size = float(args.size if args.size is not None else spec["size"])
        ps_name = family + face_suffix(spec["weight"], spec["slant"])
        hexval = spec[args.appearance]

        font = NSFont.fontWithName_size_(ps_name, size)

        if font is None:
            print(f"error: font {ps_name!r} is not installed", file=sys.stderr)
            sys.exit(1)

        entry["NSFont"] = bytes(NSArchiver.archivedDataWithRootObject_(font))
        entry["NSColor"] = bytes(
            NSArchiver.archivedDataWithRootObject_(colour_from_hex(hexval))
        )
        changed = True
        print(
            f"    [{index:2d}] {spec['label']:<32} {hexval}  {ps_name} {size:g}pt"
        )
        out.append(entry)

    if args.dry_run:
        print("    dry run; nothing written")
        return False

    plist[key] = out
    proc = subprocess.run(
        ["defaults", "import", domain, "-"],
        check=False,
        input=plistlib.dumps(plist),
    )

    if proc.returncode != 0:
        print(f"error: failed to write {domain}", file=sys.stderr)
        sys.exit(1)

    return changed


def main() -> int:
    """Parse the arguments and apply the theme to both languages."""
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--theme",
        required=True,
        help="path to a Nix file/dir exporting the scheme",
    )
    ap.add_argument(
        "--appearance",
        choices=["light", "dark"],
        default="light",
        help="palette to store (default: light — Script Editor "
        "derives dark itself)",
    )
    ap.add_argument(
        "--family", default=None, help="override the font family stem"
    )
    ap.add_argument(
        "--size", type=float, default=None, help="override the point size"
    )
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if (
        subprocess.run(
            ["pgrep", "-x", "Script Editor"], check=False, capture_output=True
        ).returncode
        == 0
    ):
        print(
            "error: Script Editor is running; quit it first or it will "
            "overwrite these settings on exit",
            file=sys.stderr,
        )
        return 1

    theme = load_theme(args.theme)
    print(
        f"  theme: {theme['meta']['name']} / {theme['meta']['application']} "
        f"({args.appearance})"
    )

    for language in SOURCES:
        apply_language(theme, language, args)

    return 0


if __name__ == "__main__":
    sys.exit(main())

"""Retarget Script Editor's syntax formatting to another font.

Script Editor keeps its styles in two per-language domains:
`com.apple.applescript` under `AppleScriptSourceAttributes`, and
`com.apple.JavaScriptOSA` under `JavaScriptSourceAttributes`. Each is an
array of dictionaries whose `NSFont` and `NSColor` values are legacy
`streamtyped` NSArchiver blobs, unreachable with `defaults` and not
safely hand-editable, since the padding rules differ between entries. So
Cocoa does the work: unarchive each NSFont, keep its point size, swap
the family while preserving the bold/italic face, re-archive. Colours
are left untouched.

Neither key exists until a style is changed by hand in that language's
Formatting tab, so a fresh machine has to be poked once per language
before this has anything to work on.

Run it with `nix run /etc/nix-darwin#script-editor-font`.
"""

import argparse
import plistlib
import subprocess
import sys

# pyobjc populates these namespaces at import time through
# `objc.loadBundle`, so no static checker can see their members. The
# suppression sits where ty reports the error with no pyobjc on the
# path, which is how an editor checks this file; given an interpreter
# that has it, ty reaches the member lines inside the parentheses
# instead and reports there.
from AppKit import NSFont  # ty: ignore[unresolved-import]
from Foundation import (  # ty: ignore[unresolved-import]
    NSArchiver,
    NSData,
    NSUnarchiver,
)

SOURCES = [
    ("com.apple.applescript", "AppleScriptSourceAttributes"),
    ("com.apple.JavaScriptOSA", "JavaScriptSourceAttributes"),
]


def face_suffix(name: str) -> str:
    """Map an existing PostScript name onto a face suffix."""
    flat = name.lower().replace("-", "").replace(" ", "")
    bold = "bold" in flat
    italic = "italic" in flat or "oblique" in flat

    if bold and italic:
        return "-BoldItalic"
    if bold:
        return "-Bold"
    if italic:
        return "-Italic"

    return "-Regular"


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--family",
        default="LigaSFMonoNerdFont",
        help="PostScript family prefix (default: %(default)s)",
    )
    ap.add_argument(
        "--size",
        type=float,
        default=None,
        help="point size (default: keep each style's existing size)",
    )
    ap.add_argument(
        "--dry-run", action="store_true", help="show changes, write nothing"
    )
    args = ap.parse_args()

    # Script Editor rewrites this whole file when it quits, so a write
    # behind its back is silently undone.
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

    overall = 0

    for domain, key in SOURCES:
        rc = retarget(domain, key, args)
        overall = overall or rc

    return overall


def retarget(domain: str, key: str, args) -> int:
    exported = subprocess.run(
        ["defaults", "export", domain, "-"], check=False, capture_output=True
    )

    if exported.returncode != 0:
        print(f"  {domain}: unreadable, skipped", file=sys.stderr)
        return 0

    plist = plistlib.loads(exported.stdout)
    entries = plist.get(key)

    if not entries:
        print(
            f"  {domain}: no {key} yet — change one style in Script Editor's "
            f"Formatting tab for this language to create it, then re-run"
        )
        return 0

    print(f"  {domain}:")
    changed = False
    out = []

    for index, entry in enumerate(entries):
        entry = dict(entry)
        blob = entry.get("NSFont")

        if blob is None:
            out.append(entry)
            continue

        data = NSData.dataWithBytes_length_(blob, len(blob))
        old = NSUnarchiver.unarchiveObjectWithData_(data)

        if old is None:
            print(
                f"    [{index:2d}] could not unarchive; left alone",
                file=sys.stderr,
            )
            out.append(entry)
            continue

        old_name = str(old.fontName())
        size = args.size if args.size is not None else float(old.pointSize())
        new_name = args.family + face_suffix(old_name)

        new = NSFont.fontWithName_size_(new_name, size)

        if new is None:
            print(
                f"error: font {new_name!r} is not installed", file=sys.stderr
            )
            return 1

        if old_name != new_name or float(old.pointSize()) != size:
            changed = True
            print(
                f"    [{index:2d}] {old_name} {old.pointSize():g}pt -> "
                f"{new_name} {size:g}pt"
            )

        entry["NSFont"] = bytes(NSArchiver.archivedDataWithRootObject_(new))
        out.append(entry)

    if not changed:
        print("    already up to date")
        return 0

    if args.dry_run:
        print("    dry run; nothing written")
        return 0

    plist[key] = out
    proc = subprocess.run(
        ["defaults", "import", domain, "-"],
        check=False,
        input=plistlib.dumps(plist),
    )

    if proc.returncode != 0:
        print(f"error: failed to write {domain}", file=sys.stderr)
        return 1

    print(f"    updated {len(out)} styles")
    return 0


if __name__ == "__main__":
    sys.exit(main())

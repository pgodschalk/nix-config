"""Set keys inside one of Terminal.app's profiles.

Terminal keeps profiles in `com.apple.Terminal` under `Window Settings`,
a dictionary of profile-name -> settings. Fonts there are
NSKeyedArchiver blobs, which `defaults` cannot write, and the
surrounding dictionary has to be read-modify-written or the other
profiles are lost.

Colours are deliberately not touched: the stock `Basic` profile stores
no colour keys at all, which is why it follows the system appearance,
and adding some would freeze it to one.
"""

import argparse
import plistlib
import subprocess
import sys

# pyobjc populates these namespaces at import time through
# `objc.loadBundle`, so no static checker can see their members.
from AppKit import NSFont  # ty: ignore[unresolved-import]
from Foundation import NSKeyedArchiver  # ty: ignore[unresolved-import]

DOMAIN = "com.apple.Terminal"


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--profile", default="Basic")
    ap.add_argument("--font", help="PostScript font name")
    ap.add_argument("--size", type=float, default=12.0)
    ap.add_argument("--columns", type=int)
    ap.add_argument("--rows", type=int)
    ap.add_argument("--bell", choices=["on", "off"])
    ap.add_argument("--option-as-meta", choices=["on", "off"])
    ap.add_argument(
        "--command",
        help="run this instead of the login shell; empty string "
        "restores the login shell",
    )
    ap.add_argument("--make-default", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if (
        subprocess.run(
            ["pgrep", "-x", "Terminal"], check=False, capture_output=True
        ).returncode
        == 0
    ):
        print(
            "error: Terminal is running; quit it first or it will overwrite "
            "these settings on exit",
            file=sys.stderr,
        )
        return 1

    exported = subprocess.run(
        ["defaults", "export", DOMAIN, "-"], check=False, capture_output=True
    )
    plist = plistlib.loads(exported.stdout) if exported.returncode == 0 else {}
    settings = plist.setdefault("Window Settings", {})
    profile = dict(
        settings.get(
            args.profile, {"name": args.profile, "type": "Window Settings"}
        )
    )

    changes = []

    if args.font:
        font = NSFont.fontWithName_size_(args.font, args.size)

        if font is None:
            print(
                f"error: font {args.font!r} is not installed", file=sys.stderr
            )
            return 1

        data = NSKeyedArchiver.archivedDataWithRootObject_requiringSecureCoding_error_(
            font, False, None
        )[0]
        profile["Font"] = bytes(data)
        changes.append(f"Font = {args.font} {args.size:g}pt")

    if args.columns is not None:
        profile["columnCount"] = args.columns
        changes.append(f"columnCount = {args.columns}")

    if args.rows is not None:
        profile["rowCount"] = args.rows
        changes.append(f"rowCount = {args.rows}")

    if args.bell is not None:
        profile["Bell"] = args.bell == "on"
        changes.append(f"Bell = {args.bell}")

    if args.option_as_meta is not None:
        profile["useOptionAsMetaKey"] = args.option_as_meta == "on"
        changes.append(f"useOptionAsMetaKey = {args.option_as_meta}")

    if args.command is not None:
        if args.command:
            # The profile's "Run command" field, with "Run inside shell"
            # on. Terminal tokenises this string itself and mangles
            # nested quotes: `/bin/zsh -l -i -c 'exec nu'` here dies
            # with `zsh:1: unmatched '`. Pass a single bare word -- e.g.
            # the `nu-login` wrapper from modules/home/nushell.nix --
            # and let that do the quoting.
            profile["CommandString"] = args.command
            profile["RunCommandAsShell"] = True
            changes.append(f"CommandString = {args.command}")
        else:
            profile.pop("CommandString", None)
            profile.pop("RunCommandAsShell", None)
            changes.append("CommandString unset (back to the login shell)")

    settings[args.profile] = profile

    if args.make_default:
        plist["Default Window Settings"] = args.profile
        plist["Startup Window Settings"] = args.profile
        changes.append(f"default and startup profile = {args.profile}")

    print(f"  profile {args.profile!r}:")

    for c in changes:
        print(f"    {c}")

    if not changes:
        print("    nothing to do")
        return 0

    if args.dry_run:
        print("    dry run; nothing written")
        return 0

    if (
        subprocess.run(
            ["defaults", "import", DOMAIN, "-"],
            check=False,
            input=plistlib.dumps(plist),
        ).returncode
        != 0
    ):
        print(f"error: failed to write {DOMAIN}", file=sys.stderr)
        return 1

    print("    written")
    return 0


if __name__ == "__main__":
    sys.exit(main())

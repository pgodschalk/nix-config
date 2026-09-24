"""Start djlsp and speak real LSP to it, as pkgs/djlsp.nix's install
check.

A file rather than a heredoc inside the derivation: an indented heredoc
terminator makes bash swallow the body, and a check that cannot fail is
worse than no check because it reads as evidence.
"""

import json
import subprocess
import sys

body = json.dumps(
    {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {"processId": None, "rootUri": None, "capabilities": {}},
    }
).encode()

proc = subprocess.Popen(
    [sys.argv[1]],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

# Bound to locals because Popen types the three pipes as optional, so
# every use of proc.stdin is an error to the type checker even though
# PIPE guarantees them.
stdin, stdout, stderr = proc.stdin, proc.stdout, proc.stderr
if stdin is None or stdout is None or stderr is None:
    sys.exit("could not open pipes to djlsp")

stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
stdin.flush()

header = b""
while b"\r\n\r\n" not in header:
    char = stdout.read(1)
    if not char:
        proc.kill()
        sys.exit(
            "djlsp closed stdout without answering initialize.\nstderr:\n"
            + stderr.read().decode(errors="replace")
        )
    header += char

length = int(
    next(
        line
        for line in header.decode().split("\r\n")
        if line.lower().startswith("content-length")
    ).split(":")[1]
)
reply = json.loads(stdout.read(length))
proc.kill()

if reply.get("id") != 1 or "result" not in reply:
    sys.exit(f"unexpected initialize reply: {reply!r}")

caps = sorted(reply["result"].get("capabilities", {}))
if not caps:
    sys.exit("djlsp answered initialize but advertised no capabilities")
print("djlsp answered initialize; capabilities:", ", ".join(caps))

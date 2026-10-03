# nixpkgs' claude-code, built inside the sandbox. nixpkgs sets
# `__noChroot` on macOS, which a daemon with `sandbox = true` refuses
# outright; the build and its version check run fine sandboxed.
{ claude-code }:

claude-code.overrideAttrs { __noChroot = false; }

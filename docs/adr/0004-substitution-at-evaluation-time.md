# Substitution happens at evaluation time, not in derivations

Scripts and config fragments live in their own files with `@name@` placeholders.
Filling them with `pkgs.replaceVars` and reading the result back is
import-from-derivation: the Linux eval then has to build a derivation it cannot
build on macOS and fails with an error naming a package. The flake's
`substituteFile` does the same substitution in pure Nix and keeps the one
safeguard that matters, an unused placeholder failing loudly. `replaceVars`
stays for files that end up as store paths rather than strings.

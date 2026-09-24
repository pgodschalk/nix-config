# The caret is load-bearing, so `remove_hat_not_builtin` cannot be
# taken: `gh` is the name this very `def` binds, and the fix it offers
# would recurse.
#
# `unhandled_external_error` likewise: a passthrough wrapper has to let
# gh's exit code reach the caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# `any` on the input side is what keeps `… | gh` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --wrapped gh [...args: string]: any -> string {
    with-env {GH_TOKEN: (fnox-secret gh GH_TOKEN)} { ^gh ...$args }
}

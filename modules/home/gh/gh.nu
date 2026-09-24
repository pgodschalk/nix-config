# The carets are load-bearing, so `remove_hat_not_builtin` cannot be
# taken: `gh` is the name this very `def` binds, and `fnox` is shadowed
# by the wrapper fnox's own shell activation defines. The fix it offers
# would recurse in the first case and go through fnox's wrapper in the
# second.
#
# `unhandled_external_error` likewise: a passthrough wrapper has to let
# gh's exit code reach the caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# `any` on the input side is what keeps `… | gh` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --env --wrapped gh [...args: string]: any -> string {
    if ($env.GH_TOKEN? | is-empty) {
        $env.GH_TOKEN = (^fnox get --profile gh GH_TOKEN | str trim)
    }
    ^gh ...$args
}

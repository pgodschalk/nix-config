# The carets are load-bearing: `resend` is the name this very `def`
# binds, and `fnox` is shadowed by the wrapper fnox's own shell
# activation defines. A passthrough wrapper also has to let resend's
# exit code reach the caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# Resolved on first use and cached in the shell's environment, so a
# shell that never runs resend pays nothing. The variable outranks the
# CLI's on-disk profile, so none is ever written.
#
# `any` on the input side is what keeps `… | resend` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --env --wrapped resend [...args: string]: any -> string {
    if ($env.RESEND_API_KEY? | is-empty) {
        $env.RESEND_API_KEY = (^fnox get -P resend RESEND_API_KEY | str trim)
    }
    ^resend ...$args
}

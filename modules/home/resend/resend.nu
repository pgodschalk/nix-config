# The caret is load-bearing: `resend` is the name this very `def`
# binds. A passthrough wrapper also has to let its exit code reach the
# caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# Resolved on first use and cached by fnox-secret, so a shell that
# never runs resend pays nothing. The variable outranks the CLI's
# on-disk profile, so none is ever written.
#
# `any` on the input side is what keeps `… | resend` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --wrapped resend [...args: string]: any -> string {
    with-env {RESEND_API_KEY: (fnox-secret resend RESEND_API_KEY)} { ^resend ...$args }
}

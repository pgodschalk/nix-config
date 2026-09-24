# The caret is load-bearing: `sentry-cli` is the name this very `def`
# binds. A passthrough wrapper also has to let its exit code reach the
# caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# SENTRY_AUTH_TOKEN takes precedence over ~/.sentryclirc, so nothing
# lands on disk and `sentry-cli login` is never needed. Resolved on
# first use, so a shell that never runs it pays nothing.
#
# `any` on the input side is what keeps `… | sentry-cli` working;
# `nothing` makes Nushell reject a pipe into the wrapper at parse time.
def --wrapped sentry-cli [...args: string]: any -> string {
    with-env {SENTRY_AUTH_TOKEN: (fnox-secret sentry SENTRY_AUTH_TOKEN)} { ^sentry-cli ...$args }
}

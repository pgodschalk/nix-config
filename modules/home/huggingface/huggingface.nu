# The caret is load-bearing: `hf` is the name this very `def`
# binds. A passthrough wrapper also has to let its exit code reach the
# caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# Resolved on first use and cached by fnox-secret, so a shell that
# never runs hf pays nothing.
#
# `any` on the input side is what keeps `… | hf` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --wrapped hf [...args: string]: any -> string {
    with-env {HF_TOKEN: (fnox-secret huggingface HF_TOKEN)} { ^hf ...$args }
}

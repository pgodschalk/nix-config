# The carets are load-bearing: `hf` is the name this very `def` binds,
# and `fnox` is shadowed by the wrapper fnox's own shell activation
# defines. A passthrough wrapper also has to let hf's exit code reach
# the caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# Resolved on first use and cached in the shell's environment, so a
# shell that never runs hf pays nothing.
#
# `any` on the input side is what keeps `… | hf` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --env --wrapped hf [...args: string]: any -> string {
    if ($env.HF_TOKEN? | is-empty) {
        $env.HF_TOKEN = (^fnox get -P huggingface HF_TOKEN | str trim)
    }

    ^hf ...$args
}

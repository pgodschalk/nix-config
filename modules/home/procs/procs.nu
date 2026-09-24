# The caret is load-bearing: `procs` is the name this very `def` binds.
# A passthrough wrapper also has to let procs' exit code reach the
# caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# procs' own `theme = "Auto"` reports dark on a light terminal, and the
# Command column is then white on white rather than visibly wrong.
# APPEARANCE is already `dark` or `light`.
#
# `any` on the input side is what keeps `… | procs` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --wrapped procs [...args: string]: any -> string {
    ^procs --theme ($env.APPEARANCE? | default auto) ...$args
}

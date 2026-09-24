# The caret is load-bearing: `glab` is the name this very `def`
# binds. A passthrough wrapper also has to let its exit code reach the
# caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# Resolved per host: a shell that moves between trees must not hand one
# GitLab's token to another. GITLAB_HOST comes from a directory's
# mise.local.toml.
#
# `any` on the input side is what keeps `… | glab` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --wrapped glab [...args: string]: any -> string {
    let host = $env.GITLAB_HOST? | default gitlab.com
    let profile = match $host {
        @hostArms@_ => "glab"
    }
    with-env {GITLAB_TOKEN: (fnox-secret $profile GITLAB_TOKEN)} {
        ^glab ...$args
    }
}

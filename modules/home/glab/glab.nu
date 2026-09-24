# The carets are load-bearing: `glab` is the name this very `def` binds,
# and `fnox` is shadowed by the wrapper fnox's own shell activation
# defines. A passthrough wrapper also has to let glab's exit code reach
# the caller rather than swallow it in a `try`.
#
# nu-lint-ignore-file: remove_hat_not_builtin, unhandled_external_error

# Cached per host rather than globally: a shell that moves between trees
# has to re-resolve, or the wrong token reaches the wrong GitLab.
# GITLAB_HOST comes from a directory's mise.local.toml.
#
# `any` on the input side is what keeps `… | glab` working; `nothing`
# makes Nushell reject a pipe into the wrapper at parse time.
def --env --wrapped glab [...args: string]: any -> string {
    let host = $env.GITLAB_HOST? | default gitlab.com
    if ($env.GITLAB_TOKEN? | is-empty) or ($env.GLAB_TOKEN_HOST? != $host) {
        let profile = match $host {
            @hostArms@_ => "glab"
        }
        load-env {
            GITLAB_TOKEN: (^fnox get -P $profile GITLAB_TOKEN | str trim)
            GLAB_TOKEN_HOST: $host
        }
    }
    ^glab ...$args
}

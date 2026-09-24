# fnox's own `fnox activate nu`, less its `fnox deactivate` wrapper and
# with the hook gated: fnox has no trust step, so a fnox.toml in any
# checkout would otherwise load secrets into the shell from wherever
# the prompt stands.
#
# The store paths cannot be missing and `cd /` cannot fail, so neither
# gets a `try`; `complete` is what keeps fnox's own failure from
# aborting the prompt. fnox's messages go to stderr as fnox printed
# them, and the `^` states that the external binary is meant.
#
# nu-lint-ignore-file: catch_builtin_error_try, try_instead_of_do
# nu-lint-ignore-file: remove_hat_not_builtin, error_make_for_non_fatal

$env.FNOX_SHELL = "nu"

def --env fnox-apply [json: string]: nothing -> nothing {
    let changes = $json | from json
    if "set" in $changes and ($changes.set | is-not-empty) {
        $changes.set | load-env
    }
    if "unset" in $changes and ($changes.unset | is-not-empty) {
        for $var in $changes.unset {
            hide-env --ignore-errors $var
        }
    }
}

# Outside the trusted directories, a session that loaded secrets is
# asked from `/` instead, where no fnox.toml applies, so fnox unloads
# them.
def --env fnox-hook []: nothing -> nothing {
    let here = $env.PWD
    let trusted = open '@trusted@'
    | any {|dir| $here == $dir or ($here | str starts-with $"($dir)/") }

    if not $trusted and ($env.__FNOX_SESSION? | is-empty) {
        return
    }

    let dir = if $trusted { $here } else { "/" }
    let result = do --ignore-errors {
        cd $dir
        ^'@fnox@' hook-env -s nu
    } | complete
    if ($result.stderr | str trim | is-not-empty) {
        print --stderr $result.stderr
    }
    if $result.exit_code == 0 and ($result.stdout | str trim | is-not-empty) {
        fnox-apply $result.stdout
    }
}

$env.config = (
    $env.config
    | upsert hooks.pre_prompt (
        $env.config.hooks.pre_prompt? | default [] | append {|| fnox-hook }
    )
)
fnox-hook

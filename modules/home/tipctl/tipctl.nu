# The store paths keep their `^`: it states that the external binary is
# meant, and `tipctl` is the name this very `def` binds. `| ignore` is
# not redundant -- without it the setup call's output is printed to the
# terminal. A failing `open --raw` is worth an error rather than a
# `try`, and a quoted path reads better than a bare word.
#
# nu-lint-ignore-file: remove_hat_not_builtin, redundant_ignore
# nu-lint-ignore-file: catch_builtin_error_try, string_may_be_bare

def --env --wrapped tipctl [...args: string]: any -> string {
    if ($env.TIPCTL_DIR? | is-empty) or (
        not ($env.TIPCTL_DIR? | default "/nonexistent" | path exists)
    ) {
        let account = "my.1password.eu"
        let dir = (^@coreutils@/bin/mktemp -d | str trim)
        ^@coreutils@/bin/chmod 700 $dir
        let key = $"($dir)/key.pem"
        ^@op@ read --account $account @keyRef@ --out-file $key --file-mode 0600
        | ignore
        let login = (^@op@ read --account $account @userRef@ | str trim)

        # A newline ends a command in nushell, so the arguments are a
        # list rather than a continuation. A bare `0600` would become
        # the integer 600 in one, which is why the mode stays inline.
        let setup = [
            setup
            -n
            $"--loginName=($login)"
            $"--apiPrivateKey=(open --raw $key)"
            --apiUseWhitelist=false
            $"--configFile=($dir)/cli-config.json"
        ]
        with-env {TMPDIR: $dir} {
            ^@tipctl@ ...$setup | ignore
        }

        ^@coreutils@/bin/rm -f $key
        $env.TIPCTL_DIR = $dir
    }

    with-env {TMPDIR: $env.TIPCTL_DIR} {
        ^@tipctl@ $"--configFile=($env.TIPCTL_DIR)/cli-config.json" ...$args
    }
}

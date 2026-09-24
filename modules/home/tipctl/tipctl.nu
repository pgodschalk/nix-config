# The store paths keep their `^`: it states that the external binary is
# meant, and `tipctl` is the name this very `def` binds. A failing
# `save` is worth an error rather than a `try`, and a quoted path reads
# better than a bare word.
#
# nu-lint-ignore-file: remove_hat_not_builtin, string_may_be_bare
# nu-lint-ignore-file: catch_builtin_error_try

def --env --wrapped tipctl [...args: string]: any -> string {
    if ($env.TIPCTL_DIR? | is-empty) or (
        not ($env.TIPCTL_DIR? | default "/nonexistent" | path exists)
    ) {
        let tmp = $env.TMPDIR? | default "/tmp" | path expand

        # Each session's copy of the key lives as long as its shell; the
        # next setup removes the copies whose shell has gone.
        let live = ps | get pid
        for stale in (glob $"($tmp)/tipctl-*") {
            let owner = try {
                $stale
                | path basename
                | parse "tipctl-{pid}-{suffix}"
                | get 0.pid
                | into int
            }
            if $owner != null and $owner not-in $live {
                try { rm --recursive --permanent $stale }
            }
        }

        let dir = (
            ^@coreutils@/bin/mktemp -d $"($tmp)/tipctl-($nu.pid)-XXXXXX"
            | str trim
        )
        let config = $"($dir)/cli-config.json"
        let account = "my.1password.eu"

        # Written here rather than by `tipctl setup`, which takes the key
        # on its command line, where every process can read it.
        {
            apiUrl: "https://api.transip.nl/v6"
            loginName: (^@op@ read --account $account @userRef@ | str trim)
            apiPrivateKey: (^@op@ read --account $account @keyRef@)
            apiUseWhitelist: false
            showConfigFilePermissionWarning: true
        }
        | to json
        | save $config
        ^@coreutils@/bin/chmod 600 $config

        $env.TIPCTL_DIR = $dir
    }

    with-env {TMPDIR: $env.TIPCTL_DIR} {
        ^@tipctl@ $"--configFile=($env.TIPCTL_DIR)/cli-config.json" ...$args
    }
}

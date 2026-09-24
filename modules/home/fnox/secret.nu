# The `^` states that the external binary is meant, and a failing
# `stor create` is the table already existing.
#
# nu-lint-ignore-file: remove_hat_not_builtin, catch_builtin_error_try

# Resolves a secret through fnox once per shell and keeps it in the
# in-memory `stor` database rather than in $env, which every child
# process inherits. Callers hand it to the one command that needs it
# with `with-env`.
def fnox-secret [profile: string, name: string]: nothing -> string {
    let key = $"($profile)/($name)"
    let cached = try {
        stor open
        | query db "SELECT value FROM fnox_secrets WHERE key = ?" --params [$key]
    } catch { [] }
    if ($cached | is-not-empty) {
        return $cached.0.value
    }

    let value = ^'@fnox@' get --profile $profile $name | str trim
    if ($value | is-not-empty) {
        try {
            stor create --table-name fnox_secrets --columns {key: str, value: str}
        }
        stor insert --table-name fnox_secrets --data-record {key: $key, value: $value}
    }
    $value
}

# Completions for external commands, which Nushell has no signatures
# for: carapace first, then fish.
#
# The fallback is dynamic rather than a list of which tool belongs to
# which engine, because carapace prints nothing for a command it has no
# spec for, so a new tool needs no edit here.
#
# `block_brace_spacing` and `closure_pipe_body_spacing` ask for a space
# after `{` that `closure_brace_pipe_spacing` then rejects, so no
# spelling of a closure satisfies all three and `{|` is the form the
# last of them demands. Both completers are reached through `do`, which
# the unused check does not follow. `^carapace` and `^fish` name the
# binaries rather than a builtin or an alias, a quoted metacharacter has
# to stay quoted to be searched for, and malformed engine output is
# worth an error rather than a silent `try`.
#
# nu-lint-ignore-file: block_brace_spacing, closure_pipe_body_spacing
# nu-lint-ignore-file: unused_variable, remove_hat_not_builtin
# nu-lint-ignore-file: string_may_be_bare, catch_builtin_error_try
let carapace_completer = {|spans: list<string>|
    let out = (^carapace ($spans | first) nushell ...$spans | complete)

    if $out.exit_code != 0 or ($out.stdout | str trim | is-empty) {
        null
    } else {
        try {
            $out.stdout | from json
        } catch { null }
    }
}

# fish emits `value<TAB>description`. --flexible because the description
# is optional and rows are ragged; --no-infer because a value like `1`
# must stay the string fish meant.
#
# The typed line reaches fish as an argument, never as fish source, so
# nothing in it can break out of the quoting.
let fish_completer = {|spans: list<string>|
    let query = $spans | str join ' '
    let out = (
        ^fish --command 'complete "--do-complete=$argv[1]"' -- $query
        | complete
    )

    if $out.exit_code != 0 or ($out.stdout | str trim | is-empty) {
        null
    } else {
        $out.stdout
        | from tsv --flexible --noheaders --no-infer
        | rename value description
        | update value {|row|
            # A path containing a space or a shell metacharacter has to
            # come back quoted, or Nushell inserts something that will
            # not parse.
            let value = $row.value | into string
            let needs_quote = (
                ['\' ',' '[' ']' '(' ')' ' ' "\t" "'" '"' '`' '{' '}' ';' '#']
                | any {|c| $c in $value }
            )

            if ($needs_quote and ($value | path exists)) {
                let expanded = if ($value starts-with '~') {
                    $value | path expand --no-symlink
                } else {
                    $value
                }

                let escaped = $expanded | str replace --all '"' '\"'
                $'"($escaped)"'
            } else {
                $value
            }
        }
    }
}

# Field by field rather than replacing the whole `external` record, so
# any other key Nushell keeps there survives a version bump.
$env.config.completions.external.enable = true
$env.config.completions.external.completer = {|spans: list<string>|
    # An alias has to be resolved first, or the completer is asked about
    # a name no engine has heard of.
    let expanded = (
        scope aliases
        | where name == ($spans | first)
        | get --optional 0.expansion
    )

    let spans = if $expanded != null {

        # Without its caret: the aliases here expand to `^bat` and the
        # like, a name neither engine knows.
        let command = $expanded | split row ' ' | first | str trim --left --char '^'
        $spans | skip 1 | prepend $command
    } else {
        $spans
    }

    let result = (do $carapace_completer $spans)

    if $result != null and ($result | is-not-empty) {
        $result
    } else {
        do $fish_completer $spans
    }
}

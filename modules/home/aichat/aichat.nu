# `??` is the name typed at the prompt, and these errors are about
# run-time state rather than any span of the caller's source.
#
# nu-lint-ignore-file: kebab_case_commands, add_label_to_error

# Not in home.sessionVariables, so it is claimed only where the shell
# really is Nushell.
$env.AICHAT_SHELL = "@targetShell@"

# Asks for a command in plain English and puts it on the next prompt's
# editing line, so nothing runs until Enter is pressed. `-e` explains
# it first.
#
# `--wrapped` because a plain rest parameter makes Nushell reject
# `?? tar excluding --exclude=.git` as an unknown flag, so the flags
# are filtered out below instead.
def --wrapped "??" [...args: string] {
    let flags = ["-e" "--explain"]
    let explain = $args | any {|a| $a in $flags }
    let query = (
        $args
        | where $it not-in $flags
        | str join " "
        | str trim
    )

    if ($query | is-empty) {
        error make --unspanned {msg: "?? needs a description, e.g. `?? ffmpeg mp4 to mkv`"}
    }

    # Comes back empty when 1Password has locked, and failing here beats
    # an API error that looks like a bad key.
    let key = fnox-secret aichat CLAUDE_API_KEY
    if ($key | is-empty) {
        error make --unspanned {msg: "could not resolve CLAUDE_API_KEY from 1Password -- is the app unlocked?"}
    }

    let cmd = with-env {CLAUDE_API_KEY: $key} {
        print --no-newline ⌛
        let raw = aichat -e $query | complete
        print --no-newline "\r \r"

        if $raw.exit_code != 0 {
            error make --unspanned {msg: $"aichat failed: ($raw.stderr | str trim)"}
        }

        let cmd = (?_strip_fence $raw.stdout)

        if ($cmd | is-empty) {
            error make --unspanned {msg: "no command generated"}
        }

        if $explain {
            aichat -r %explain-shell% $cmd
            print ""
        }
        $cmd
    }

    commandline edit --replace $cmd
}

# Undoes the two formatting habits that survive "output nothing else": a
# fenced block, and an answer wrapped in backticks.
def ?_strip_fence [text: string]: nothing -> string {
    let t = $text | str trim

    let inner = if ($t | str starts-with "```") {
        $t
        | lines
        | skip 1
        | take until {|l| $l | str starts-with "```" }
        | str join "\n"
    } else {
        $t
    }

    $inner | str trim | str trim --char "`" | str trim
}

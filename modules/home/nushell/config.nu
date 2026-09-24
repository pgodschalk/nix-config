# Every `^` is deliberate: the external binary is meant rather than a
# builtin or one of this configuration's aliases, and `def open` below
# would recurse without it. `catch_builtin_error_try` and
# `unhandled_external_error` are declined for the mirror reason -- a
# wrapper lets a failure reach the caller instead of swallowing it.
# `bat_to_open` and `tail_to_last` would swap a renderer and a follow
# for nushell's parser and `last`, which do another job;
# `string_may_be_bare` would turn a quoted delimiter into a bare word,
# and in the theme block a quoted variant into a call to the command of
# that name; `$files.0` is one element rather than a list to spread;
# and the theme module's path is only known at run time, so `use`
# cannot be validated here.
#
# nu-lint-ignore-file: remove_hat_not_builtin, bat_to_open
# nu-lint-ignore-file: unhandled_external_error, catch_builtin_error_try
# nu-lint-ignore-file: tail_to_last, string_may_be_bare
# nu-lint-ignore-file: spread_list_to_external, add_label_to_error
# nu-lint-ignore-file: dynamic_script_import

def --wrapped battail [...args: string]: any -> string {
    ^tail -f ...$args | ^bat --paging=never --language=log
}

# bat cannot guess a syntax from a pipe, so the path half of `rev:path`
# is handed to it as --file-name to guess from.
def batshow [revpath: string]: any -> string {
    ^git show $revpath | ^bat --file-name ($revpath | split row ":" | last)
}

# Copies stdin to the clipboard with no trailing newline, which would
# break the value being pasted.
#
# The tool is chosen at call time rather than by Nix, because on a Linux
# host either may be present. Anything can be put on the clipboard, so
# `any` is the honest input type.
#
# nu-lint-ignore: missing_in_type
def c []: any -> string {
    let payload = $in | ^tr -d "\n"

    if @isDarwin@ {
        $payload | ^pbcopy
    } else if (which xclip | is-not-empty) {
        $payload | ^xclip -selection clipboard
    } else if (which xsel | is-not-empty) {
        $payload | ^xsel --clipboard
    } else {
        error make --unspanned {msg: "no clipboard command: tried pbcopy, xclip, xsel"}
    }
}

# No -p flag: nushell's `mkdir` is a builtin and creates intermediate
# directories unconditionally. `--env` is what makes the `cd` outlive
# the call.
def --env mkd [path: path, ...rest: path]: nothing -> nothing {
    mkdir $path ...$rest
    cd ([$path] | append $rest | last)
}

# Only a single directory argument goes to the desktop opener; the rest
# keeps nushell's builtin, which reads a file into structured data. An
# alias binds when it is defined, so `nu-open` still names the builtin
# after the `def` shadows it, and `--raw` is passed explicitly because
# spreading a flag as a string makes it a file name.
alias nu-open = open

# The output is whatever nushell parses out of the file, so `any` is the
# honest type rather than a missing annotation.
# nu-lint-ignore: missing_output_type
def open [--raw(-r), ...files: path]: nothing -> any {
    if ($files | length) == 1 and ($files.0 | path type) == dir {
        ^@opener@ $files.0
    } else if $raw {
        nu-open --raw ...$files
    } else {
        nu-open ...$files
    }
}

def o [target: path = "."]: any -> string {
    ^@opener@ $target
}

# Not `exec $env.SHELL -l`: $SHELL is /bin/zsh, the login shell, so that
# would land in zsh rather than back in nushell. `nu-login` is what the
# terminals themselves run.
def reload []: nothing -> nothing {
    exec @nuEntry@
}

# Named bathelp rather than help, because `help` is a nushell builtin
# worth keeping.
def --wrapped bathelp [...args: string]: any -> string {
    ^($args | first) ...($args | skip 1) --help | ^bat --plain --language=help
}

const THEME_EXTRAS = "@themeExtras@"

def banner [title: string] {
    print ""
    print $"(ansi blue_bold)== ($title)(ansi reset)"
}

def note [msg: string] { print $"  ($msg)" }
def ok [msg: string] { print $"  (ansi green)ok(ansi reset)   ($msg)" }
def warn [msg: string] { print $"  (ansi yellow)note(ansi reset) ($msg)" }

# Reports rather than aborting, so one unreachable service does not stop
# the pass.
#
# The command must stay a list: as rest-args, Nushell reads a leading
# `--flag` as a flag to `run-step` itself and refuses to parse.
# nu-lint-ignore: list_param_to_variadic
def run-step [label: string, cmd: list<string>]: nothing -> nothing {
    let result = (^($cmd | first) ...($cmd | skip 1) | complete)

    if $result.exit_code == 0 {
        ok $label
        if ($result.stdout | str trim | is-not-empty) {
            for l in ($result.stdout | str trim | lines) { note $"     ($l)" }
        }
    } else {
        warn $"($label) failed \(exit ($result.exit_code)\)"

        for l in (
            $result.stderr
            | str trim
            | lines
            | first 3
        ) { note $"     ($l)" }
    }
}

# Reported rather than installed: automatic macOS updates are fully on,
# so a second installer racing them buys nothing and `-R` would reboot
# in the middle of a chore.
def update-apple []: nothing -> nothing {
    banner "Apple software updates"
    let out = /usr/sbin/softwareupdate -l | complete
    let text = $"($out.stdout)($out.stderr)"

    if $text =~ "No new software available" {
        ok "macOS is up to date"
    } else {
        for l in (
            $text
            | str trim
            | lines
            | where ($it | str trim | is-not-empty)
        ) {
            note $l
        }
        warn "install from System Settings, or `sudo -H softwareupdate -i -a`"
    }
}

def update-mas [dry: bool]: nothing -> nothing {
    banner "Mac App Store"
    let outdated = mas outdated | complete

    if $outdated.exit_code != 0 {
        warn $"mas outdated failed \(exit ($outdated.exit_code)\)"
        for l in (
            $outdated.stderr
            | str trim
            | lines
            | first 3
        ) {
            note $"     ($l)"
        }
        return
    }

    if ($outdated.stdout | str trim | is-empty) {
        ok "every App Store app is current"
        return
    }

    for l in ($outdated.stdout | str trim | lines) { note $l }

    if $dry {
        note "would run: mas upgrade"
    } else {
        run-step "mas upgrade" [mas upgrade]
    }
}

def update-caches [dry: bool]: nothing -> nothing {
    banner "Tool caches"

    if $dry {
        note "would run: tldr --update"
    } else {
        run-step "tldr pages" [tldr "--update"]
    }

    # Plugins are downloads, so they update out of band from the
    # `enabledPlugins` list that declares them. A `@synced` one has no
    # marketplace behind it and `claude plugin update` refuses it.
    let all = (
        claude plugin list
        | lines
        | where $it =~ ❯
        | each {|l| $l | str replace --all --regex '^\s*❯\s*' '' | str trim }
    )
    let synced = $all | where ($it | str ends-with @synced)
    let plugins = $all | where not ($it | str ends-with @synced)

    if ($plugins | is-empty) {
        warn "no updatable Claude Code plugins"
    } else if $dry {
        note $"would update ($plugins | length) Claude Code plugins"
    } else {
        # Only a plugin that actually moved is worth a line.
        mut moved = 0
        mut failed = 0

        for pl in $plugins {
            let r = claude plugin update $pl | complete
            let out = $"($r.stdout)($r.stderr)"

            if $r.exit_code != 0 {
                $failed += 1
                warn $"plugin ($pl) failed"

                for l in (
                    $out
                    | str trim
                    | lines
                    | first 2
                ) { note $"     ($l)" }
            } else if $out =~ "already at the latest version" {
                continue
            } else {
                $moved += 1
                ok $"plugin ($pl) updated"
            }
        }

        let current = ($plugins | length) - $moved - $failed
        ok $"plugins: ($moved) updated, ($current) already current"
    }

    if ($synced | is-not-empty) {
        note (
            $"($synced | length) claude.ai-synced plugins are managed"
            + " on claude.ai, not here"
        )
    }
}

# MetalToolchain is the only component `xcodebuild -downloadComponent`
# documents; the predictive-completion model is a UI-only download and
# is in the manual list instead.
def update-xcode [dry: bool]: nothing -> nothing {
    banner "Xcode components"

    if $dry {
        note "would run: xcodebuild -downloadComponent MetalToolchain"
        return
    }

    run-step "Metal toolchain" [
        /usr/bin/xcodebuild
        "-downloadComponent" MetalToolchain
    ]
}

# A checkout rather than a flake input, so nothing else moves it.
# dracula-pro itself is a paid download rather than a repository, so
# only the extras are pulled.
def update-checkouts [dry: bool]: nothing -> nothing {
    banner "Theme working copies"
    let repo = $THEME_EXTRAS

    if not ($"($repo)/.git" | path exists) {
        warn $"($repo) is not a git checkout; skipped"
        return
    }

    if $dry {
        note (
            $"would run: git --git-dir ($repo)/.git"
            + $" --work-tree ($repo) pull --ff-only"
        )
    } else {
        run-step dracula-pro-extras [
            git
            "--git-dir" $"($repo)/.git"
            "--work-tree" $repo
            pull
            "--ff-only"
        ]
    }
}

def report-manual []: nothing -> nothing {
    banner "Manual steps"

    let items = [
        1Password
        Agentastic.dev
        "Apple Books"
        "Citrix Workspace"
        Discord
        "Final Cut Pro, Motion, Compressor"
        "GarageBand, Logic Pro, MainStage"
        "Google Drive"
        "Microsoft Teams"
        "Secretive -- https://github.com/maxgoedjen/secretive/releases"
        Setapp
        Wipr
        Xcode
    ]

    for i in $items { note $"- ($i)" }
}

def main [
    --dry-run # report what would happen, change nothing
] {
    let dry = $dry_run

    print $"(ansi blue_bold)update-all(ansi reset)"

    if $dry { warn "dry run: nothing will be changed" }

    update-apple
    update-mas $dry
    update-caches $dry
    update-xcode $dry
    update-checkouts $dry

    report-manual

    print ""
    print $"(ansi green_bold)done(ansi reset)"
}

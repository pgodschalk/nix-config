.extraKnownMarketplaces["nix-config"] = {
    source: {
        source: "directory",
        path: $path
    }
} |
    .enabledPlugins["nix-lsp@nix-config"] = true |
    .enabledPlugins = ((.enabledPlugins // {}) | with_entries(select(.key | endswith("@claude-plugins-official") | not))) + $plugins |
    .syncClaudeAiPlugins = false |
    .permissions.defaultMode = "auto" |
    .permissions.deny = ((.permissions.deny // []) + [
        "Bash(security find-generic-password:*)",
        "Bash(security find-internet-password:*)",
        "Bash(security dump-keychain:*)",
        "Bash(/usr/bin/security find-generic-password:*)",
        "Bash(/usr/bin/security find-internet-password:*)",
        "Bash(/usr/bin/security dump-keychain:*)"
    ] | unique) |
    .remoteControlAtStartup = true |
    .outputStyle = "Concise" |
    .voiceEnabled = true |
    .sandbox.enabled = true |
    .statusLine = {
        type: "command",
        command: $statusline,
        padding: 0
    } |
    .hooks.PostToolUse = ((.hooks.PostToolUse // [

    ]) |
        map(select(any(.hooks[]?; .command? // "" | endswith("/bin/claude-md-lint")) | not)) + [
            {
                matcher: "Write|Edit",
                hooks: [
                    {
                        type: "command",
                        command: $mdlint
                    }
                ]
            }
        ])

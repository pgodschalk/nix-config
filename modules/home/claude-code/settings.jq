.extraKnownMarketplaces["nix-config"] = {
    source: {
        source: "directory",
        path: $path
    }
} |
    .enabledPlugins["nix-lsp@nix-config"] = true |
    .enabledPlugins = ((.enabledPlugins // {}) | with_entries(select(.key | endswith("@claude-plugins-official") | not))) + $plugins |
    .permissions.defaultMode = "auto" |
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

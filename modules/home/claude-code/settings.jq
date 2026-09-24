.extraKnownMarketplaces["nix-config"] = {
    source: {
        source: "directory",
        path: $path
    }
} |
    .enabledPlugins["nix-lsp@nix-config"] = true |
    .enabledPlugins = (.enabledPlugins + $plugins) |
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
        map(select(.matcher != "Write|Edit")) + [
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

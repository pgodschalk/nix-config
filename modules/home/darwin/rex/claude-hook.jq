# The entry `rex skill setup --agent claude` writes, kept verbatim so
# `rex skill status` reports it current rather than adding a second.
.hooks.SessionStart = ((.hooks.SessionStart // []) |
    map(select(any(.hooks[]?; .command? // "" | contains("rex __internal session-start")) | not)) + [
        {
            hooks: [
                {
                    type: "command",
                    command: "/bin/sh -c 'rex __internal session-start --agent claude 2>/dev/null || true'",
                    timeout: 5
                }
            ]
        }
    ])

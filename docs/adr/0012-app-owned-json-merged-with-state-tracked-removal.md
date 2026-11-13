# App-owned JSON is merged with state-tracked removal and a strategy per key

Apps such as Claude Desktop rewrite their own JSON settings file, so a link is
replaced and a file rendered whole discards the app's own edits. One option,
`my.mergedSettings`, owns the merge into these files instead: at activation each
entry's declared value is merged into the app's file and kept as state, so
whatever Nix stops declaring is taken back out at the next switch and what the
app wrote outside a `replace` key survives. One deep merge does not fit every
key. Some are Nix's whole, such as an MCP server set where a server added in the
app must not stay; they take `replace`. Some are lists both sides add to, such
as an agent's packages; they take `union`, compared by value. Every other key is
deep-merged. A strategy sits at any depth, spelled in the value's own shape, so
one list inside an object both sides write is merged on its own while its
siblings are deep-merged. The strategies are kept as state too, so a key dropped
together with its strategy is still taken back the way it was merged. A file
that is not valid JSON, or that the app has reshaped so the merge fails, is left
as it is, state included, with a warning naming the entry: one broken file must
not stop the activation. The work layer's apps belong on the same option.

Claude Code's `settings.json` is one entry, and every module that writes into
it, jouet and rex included, adds to that entry's value rather than running a
writer of its own. Orca adds its own agent-hook groups to the same per-event
lists at run time and removes only those, so every `hooks.<Event>` takes
`union`. Claude Code's schema allows no key a group could name its owner in, so
the state is what tells Nix's groups from Orca's. An event name Claude Code does
not know fails evaluation, because Claude Code only warns about one and never
runs its hooks.

The costs:

- An entry removed from the option is no longer merged at all, so what it
  declared stays in the file; declaring its value as `{}` for one switch takes
  it back first.
- When `union` takes back the last elements of a key no longer declared, the
  empty list stays in the file.
- A skipped file is retried, and warned about, at every switch until it is
  repaired.
- A group an app writes identical to a declared one is adopted at the first
  merge, and taken back with it once Nix stops declaring it.
- Claude Code's hook events are listed in `claude-code.nix`, so an event added
  upstream fails evaluation until the list has it.
- A rollback to a generation older than Claude Code's entry runs that
  generation's writers again, and they reinstall their agent-hook groups without
  touching the state, so at the next switch forward the merge keeps those groups
  as the app's own. Removing them is manual: delete from
  `~/Library/Application Support/claude-code/settings.json`, before or after
  switching forward, the groups whose command ends in `/bin/claude-vcs-guard` or
  `/bin/claude-md-lint`, or contains `jouet hook claude` (followed by a space)
  or `rex __internal session-start`.

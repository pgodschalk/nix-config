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

The costs:

- An entry removed from the option is no longer merged at all, so what it
  declared stays in the file; declaring its value as `{}` for one switch takes
  it back first.
- When `union` takes back the last elements of a key no longer declared, the
  empty list stays in the file.
- A skipped file is retried, and warned about, at every switch until it is
  repaired.

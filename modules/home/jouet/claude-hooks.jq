# Replaces every hook group running `jouet hook claude` with
# $jouet[0], so an event a newer jouet no longer hooks is dropped
# rather than left behind. Every other group is kept as it is.
def jouet_group: any(.hooks[]?; (.command? // "") | contains("jouet hook claude "));

.hooks = (
    (.hooks // {})
    | map_values(map(select(jouet_group | not)))
    | with_entries(select(.value != []))
) |
    reduce ($jouet[0] | to_entries[]) as $event (.;
        .hooks[$event.key] = ((.hooks[$event.key] // []) + $event.value)
    )

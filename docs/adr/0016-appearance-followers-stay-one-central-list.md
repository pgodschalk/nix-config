# Appearance followers stay one central list

The followers, the tools that can follow neither the Appearance nor an
environment variable, are listed in one place: `links` in the module that holds
the switch, beside Claude Code's theme key, which the same switch rewrites. A
Registry was the alternative, each tool's module declaring its own follower,
with a machine that runs no switch linking the dark Variant statically. Issue
[#31](https://github.com/pgodschalk/nix-config/issues/31), closed on 2026-11-10,
rules that fallback out: the switch becomes portable and follows one Appearance
state that every machine keeps, remotes get the theme checkouts as store paths,
and a machine without them gets default palettes rather than a fixed Variant. No
machine is left for a static link to serve. Without the fallback, a Registry
only spreads a handful of entries over as many modules, while the list shows in
one place which tools still need a link moved under them.

The cost is that a follower's files are named twice: Helix's dark and light
configurations are written by `modules/home/helix.nix` and named again in
`links`.

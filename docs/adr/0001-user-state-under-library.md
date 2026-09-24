# User state lives under ~/Library, not in dotfiles

macOS has its own file-system hierarchy, and most Nix setups ignore it in favour
of XDG dotfiles in the home directory. This configuration remaps XDG to
`~/Library` (Application Support and Caches), tells every tool that can be told
where to keep its state, and tolerates a dotfile only when the tool hardcodes
the name. The cost is the occasional tool tripping over the space in
"Application Support"; the gain is a home directory holding only what the user
put there.

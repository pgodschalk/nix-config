# The work layer is a separate private flake

Employer-specific configuration cannot be published with this repository. Rather
than a private directory, an encrypted subtree or a fork, it is a separate flake
consumed as the `work` input. It exports `darwinModules.default` for the Mac
host, carrying both halves of the home layer through `sharedModules`, and
`homeModules.default` with the portable half alone for a standalone home
configuration; `stubs/work` is an empty stand-in that exports the same two
attributes. The stub is what lets CI and any other machine evaluate this
repository unchanged.

# The work layer is a separate private flake

Employer-specific configuration cannot be published with this repository. Rather
than a private directory, an encrypted subtree or a fork, it is a separate flake
consumed as the `work` input, exporting one module for each half, with
`stubs/work` as an empty stand-in that exports the same two attributes. The stub
is what lets CI and any other machine evaluate this repository unchanged.

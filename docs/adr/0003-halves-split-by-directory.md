# The macOS and portable halves are split by directory

A module that must also serve a future NixOS or WSL host cannot carry an
`isDarwin` guard in every branch without the guards rotting. macOS-only modules
live in their own directories, `modules/darwin/` and `modules/home/darwin/`, and
a non-macOS host simply never imports them. A throwaway Linux home configuration
exists only to be evaluated, because that evaluation is the only thing that
catches a macOS assumption leaking into the portable half.

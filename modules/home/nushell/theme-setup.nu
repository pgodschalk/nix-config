# The theme module's path is only known at run time, so `use` cannot
# be checked here.
#
# A quoted variant name has to stay quoted: bare, it would be a call
# to the command of that name, which is what the blocks below
# deliberately do with `pro` and `alucard`.
#
# nu-lint-ignore-file: dynamic_script_import, string_may_be_bare
# catch_builtin_error_try: the path `open` is given is a store path
# substituted at build time, so a failure there means a broken
# activation and has to be loud rather than caught.
# nu-lint-ignore-file: catch_builtin_error_try

# There is no system appearance to read here, so the variant comes from
# $APPEARANCE, which modules/home/darwin/ssh.nix sends over SSH, and is
# applied once rather than watched.
use ($nu.default-config-dir | path join "dracula-pro.nu") *
let theme_dirs = (open '@themeDirs@')
let variant = $env.APPEARANCE? | default "dark"
let stem = (if $variant == "light" { "alucard" } else { "pro" })
$env.config.color_config = (if $stem == "pro" { pro } else { alucard })
load-env (env_for $theme_dirs $stem)
$env.APPEARANCE = $variant
